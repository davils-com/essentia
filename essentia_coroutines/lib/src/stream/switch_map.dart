/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/src/context/coroutine_context.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_zone.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/stream/cancellation_watch.dart';
import 'package:essentia_coroutines/src/stream/subscription_cancel.dart';
import 'package:meta/meta.dart';

/// Maps every element of [source] to an inner stream with [convert] and
/// emits the events of the most recent inner stream only.
///
/// When [source] emits, the subscription of the previous inner stream is
/// cancelled, and the new inner stream is listened to once that cancel
/// completed; [source] is paused meanwhile. Errors of [source], of
/// [convert], of the inner streams and of cancelling an inner stream are
/// passed on without ending the result, except a cancellation of
/// cancelling an inner stream, which is how its superseded work ends. The
/// result ends once [source] and the current inner stream have ended.
///
/// Every element gets a job of its own: [convert] runs and the inner stream
/// is listened to in a zone carrying that job, laid over the context of the
/// listener. The job is cancelled right before the inner stream is
/// replaced or the result is cancelled, so cancellable waits of the
/// superseded work - a `delay` in an `async*` generator, a `Deferred` it
/// awaits - end at once with a `CancellationException` instead of holding
/// up the cancel. The job of the current inner stream is cancelled as well
/// when the job the result was listened in is cancelled.
///
/// Pause and resume reach [source] and the current inner stream, and
/// cancelling the result cancels both.
///
/// Returns a stream that is a broadcast stream exactly when [source] is; a
/// broadcast result shares one subscription of [source] between all of its
/// listeners.
@internal
Stream<S> switchMap<T, S>(
  Stream<T> source,
  Stream<S> Function(T element) convert,
) {
  final bool broadcast = source.isBroadcast;
  final controller = broadcast
      ? StreamController<S>.broadcast(sync: true)
      : StreamController<S>(sync: true);
  controller.onListen = () {
    final CoroutineContext context = currentCoroutineContext();
    StreamSubscription<S>? innerSubscription;
    Job? innerJob;
    var outerDone = false;

    void listenToInner(Zone zone, Stream<S> inner) {
      innerSubscription = zone.run(
        () => inner.listen(
          controller.add,
          onError: controller.addError,
          onDone: () {
            innerSubscription = null;
            if (outerDone) {
              unawaited(controller.close());
            }
          },
        ),
      );
      if (controller.isPaused) {
        innerSubscription?.pause();
      }
    }

    final StreamSubscription<T> outer = source.listen(
      null,
      onError: controller.addError,
      onDone: () {
        outerDone = true;
        if (innerSubscription == null) {
          unawaited(controller.close());
        }
      },
    );

    Future<void> replace(
      StreamSubscription<S> previous,
      Zone zone,
      Stream<S> inner,
    ) async {
      outer.pause();
      try {
        await keepInZone(previous.cancel());
      } on Object catch (error, stackTrace) {
        if (error is! CancellationException) {
          controller.addError(error, stackTrace);
        }
      }
      if (!broadcast && !controller.hasListener) {
        zone.run(() => inner.listen(null)).cancel().ignore();
        return;
      }
      outer.resume();
      listenToInner(zone, inner);
    }

    outer.onData((element) {
      final job = Job();
      final Zone zone = forkCoroutineZone(context + job);
      final Stream<S> inner;
      try {
        inner = zone.run(() => convert(element));
      } on Object catch (error, stackTrace) {
        job.cancel();
        controller.addError(error, stackTrace);
        return;
      }
      innerJob?.cancel();
      innerJob = job;
      final previous = innerSubscription;
      if (previous == null) {
        listenToInner(zone, inner);
        return;
      }
      innerSubscription = null;
      unawaited(replace(previous, zone, inner));
    });
    final Disposable? watch = watchCancellation(
      (cause) => innerJob?.cancel(cause),
    );
    if (!broadcast) {
      controller
        ..onPause = () {
          innerSubscription?.pause();
          outer.pause();
        }
        ..onResume = () {
          innerSubscription?.resume();
          outer.resume();
        };
    }
    controller.onCancel = () {
      watch?.dispose();
      innerJob?.cancel();
      final Future<void>? innerCancel = innerSubscription?.cancel();
      return <Future<void>>[
        if (!outerDone) keepInZone(outer.cancel()),
        if (innerCancel != null) keepInZone(innerCancel),
      ].wait.then((_) {});
    };
  };
  return controller.stream;
}
