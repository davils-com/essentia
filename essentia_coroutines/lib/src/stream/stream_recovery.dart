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

import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/flow/flow_collector.dart';
import 'package:essentia_coroutines/src/stream/controller_collector.dart';
import 'package:essentia_coroutines/src/stream/subscription_cancel.dart';

/// How often `retry` tries again unless told otherwise: the largest
/// integer every platform counts exactly.
const _unlimited = 9007199254740991;

/// Retries on every error, the default predicate of `retry`.
///
/// Returns `true`.
bool _always(Object cause) => true;

/// The error handling operators for streams.
///
/// They treat the first error of this stream as its end: the subscription
/// is cancelled, and the operator decides what comes next. A
/// [CancellationException] is never handled; it is passed on and ends the
/// result.
extension StreamRecovery<T> on Stream<T> {
  /// Listens to this stream again after an error, up to [retries] times
  /// and as long as [predicate] agrees.
  ///
  /// It is `retryWhen` with an attempt below [retries] and [predicate].
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  ///
  /// Throws an [ArgumentError] if [retries] is not positive.
  Stream<T> retry({
    int retries = _unlimited,
    FutureOr<bool> Function(Object cause) predicate = _always,
  }) {
    if (retries <= 0) {
      throw ArgumentError(
        'Expected positive amount of retries, but had $retries',
        'retries',
      );
    }
    return retryWhen(
      (cause, attempt) => attempt < retries ? predicate(cause) : false,
    );
  }

  /// Listens to this stream again after an error whenever [predicate]
  /// says so.
  ///
  /// On an error the subscription is cancelled, and [predicate] gets the
  /// error and the number of the attempt, starting at zero. When it
  /// returns `true`, this stream is listened to again; when it returns
  /// `false`, the error is passed on and the result ends. An error of
  /// [predicate] is passed on instead. A waiting [predicate] can wait with
  /// `delay` for a backoff.
  ///
  /// Listening again needs a stream that can be listened to more than
  /// once: a broadcast stream, `Stream.multi`, or a stream made by a
  /// function each time. A single subscription stream that already had its
  /// listener fails with a [StateError], which is passed on and ends the
  /// result.
  ///
  /// ```dart
  /// fetchAll().retryWhen((cause, attempt) async {
  ///   if (cause is! IOException || attempt >= 3) {
  ///     return false;
  ///   }
  ///   await delay(Duration(seconds: 1 << attempt));
  ///   return true;
  /// });
  /// ```
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  Stream<T> retryWhen(
    FutureOr<bool> Function(Object cause, int attempt) predicate,
  ) => Stream<T>.multi((controller) {
    StreamSubscription<T>? current;
    var attempt = 0;

    void end(Object error, StackTrace stackTrace) {
      controller.addError(error, stackTrace);
      unawaited(controller.close());
    }

    void subscribe(
      Future<void> Function(Object error, StackTrace stackTrace) recover,
    ) {
      try {
        current = listen(
          controller.addSync,
          onError: (Object error, StackTrace stackTrace) =>
              unawaited(recover(error, stackTrace)),
          onDone: controller.closeSync,
        );
      } on Object catch (error, stackTrace) {
        end(error, stackTrace);
        return;
      }
      if (controller.isPaused) {
        current?.pause();
      }
    }

    Future<void> recover(Object error, StackTrace stackTrace) async {
      final failed = current;
      current = null;
      if (failed != null) {
        await keepInZone(failed.cancel());
      }
      if (error is CancellationException) {
        end(error, stackTrace);
        return;
      }
      final bool again;
      try {
        again = await predicate(error, attempt);
      } on Object catch (predicateError, predicateStackTrace) {
        end(predicateError, predicateStackTrace);
        return;
      }
      if (!controller.hasListener) {
        return;
      }
      if (!again) {
        end(error, stackTrace);
        return;
      }
      attempt++;
      subscribe(recover);
    }

    subscribe(recover);
    controller
      ..onPause = () {
        current?.pause();
      }
      ..onResume = () {
        current?.resume();
      }
      ..onCancel = () => keepInZone(current?.cancel() ?? Future<void>.value());
  }, isBroadcast: isBroadcast);

  /// Ends the stream on its first error and runs [action] instead, which
  /// may emit what the stream continues with.
  ///
  /// The subscription of this stream is cancelled, and [action] gets the
  /// collector `it` of the result, the error and its stack trace. The
  /// result ends once [action] completed; an error [action] throws is
  /// passed on before. A [CancellationException] is passed on without
  /// running [action]. Unlike `handleError`, the stream does not go on
  /// after the error.
  ///
  /// ```dart
  /// prices.catchError((it, error, stackTrace) => it.emit(lastKnownPrice));
  /// ```
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  Stream<T> catchError(
    FutureOr<void> Function(
      FlowCollector<T> it,
      Object error,
      StackTrace stackTrace,
    )
    action,
  ) => Stream<T>.multi((controller) {
    final collector = ControllerCollector<T>(controller);

    Future<void> recover(
      StreamSubscription<T> failed,
      Object error,
      StackTrace stackTrace,
    ) async {
      await keepInZone(failed.cancel());
      if (error is CancellationException) {
        controller.addError(error, stackTrace);
        await controller.close();
        return;
      }
      try {
        await action(collector, error, stackTrace);
      } on Object catch (actionError, actionStackTrace) {
        controller.addError(actionError, actionStackTrace);
      }
      await controller.close();
    }

    final StreamSubscription<T> subscription = listen(
      controller.addSync,
      onDone: controller.closeSync,
    );
    subscription.onError(
      (Object error, StackTrace stackTrace) =>
          unawaited(recover(subscription, error, stackTrace)),
    );
    controller
      ..onPause = subscription.pause
      ..onResume = () {
        subscription.resume();
        collector.release();
      }
      ..onCancel = () {
        collector.release();
        return keepInZone(subscription.cancel());
      };
  }, isBroadcast: isBroadcast);
}
