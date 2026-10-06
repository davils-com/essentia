/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:meta/meta.dart';

/// Maps every element of [source] to an inner stream with [convert] and
/// emits the events of the most recent inner stream only, the counterpart
/// of Kotlin's `flatMapLatest`.
///
/// When [source] emits, the subscription of the previous inner stream is
/// cancelled, and the new inner stream is listened to once that cancel
/// completed; [source] is paused meanwhile. Errors of [source], of
/// [convert], of the inner streams and of cancelling an inner stream are
/// passed on without ending the result. The result ends once [source] and
/// the current inner stream have ended.
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
    StreamSubscription<S>? innerSubscription;
    var outerDone = false;

    void listenToInner(Stream<S> inner) {
      innerSubscription = inner.listen(
        controller.add,
        onError: controller.addError,
        onDone: () {
          innerSubscription = null;
          if (outerDone) {
            unawaited(controller.close());
          }
        },
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
      Stream<S> inner,
    ) async {
      outer.pause();
      try {
        await previous.cancel();
      } on Object catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      }
      if (!broadcast && !controller.hasListener) {
        inner.listen(null).cancel().ignore();
        return;
      }
      outer.resume();
      listenToInner(inner);
    }

    outer.onData((element) {
      final Stream<S> inner;
      try {
        inner = convert(element);
      } on Object catch (error, stackTrace) {
        controller.addError(error, stackTrace);
        return;
      }
      final previous = innerSubscription;
      if (previous == null) {
        listenToInner(inner);
        return;
      }
      innerSubscription = null;
      unawaited(replace(previous, inner));
    });
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
      final cancels = <Future<void>>[
        if (!outerDone) outer.cancel(),
        ?innerSubscription?.cancel(),
      ];
      if (cancels.isEmpty) {
        return null;
      }
      return cancels.wait.then((_) {});
    };
  };
  return controller.stream;
}
