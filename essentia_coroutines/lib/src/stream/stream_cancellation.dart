/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/flow/shared_flow.dart';
import 'package:essentia_coroutines/src/stream/cancellation_watch.dart';
import 'package:essentia_coroutines/src/stream/subscription_cancel.dart';

/// Kotlin's cancellation operator for streams.
extension StreamCancellation<T> on Stream<T> {
  /// Ends the stream for a listener once the job it listened in is
  /// cancelled, Kotlin's `cancellable`.
  ///
  /// The subscription of this stream is cancelled, and the listener gets
  /// the [CancellationException] of the job as an error event before the
  /// result is done for it, so `await for` over a stream that never ends
  /// gives up with that exception instead of keeping the cancelled job
  /// waiting. A job that completes normally does not end the stream, and a
  /// listener outside every job is never ended. A [SharedFlow] is
  /// cancellable already and is returned as it is.
  ///
  /// Events go to the listener in the frame they arrive in, so a listener
  /// that pauses pauses this stream before the next event. When listening
  /// to this stream throws, such as the [StateError] of a single
  /// subscription stream listened to a second time, the error becomes the
  /// only event of the result instead of an uncaught error.
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  Stream<T> cancellable() {
    if (this is SharedFlow<T>) {
      return this;
    }
    return Stream<T>.multi((controller) {
      final StreamSubscription<T> subscription;
      try {
        subscription = listen(
          controller.addSync,
          onError: controller.addErrorSync,
          onDone: controller.closeSync,
        );
      } on Object catch (error, stackTrace) {
        controller.addError(error, stackTrace);
        unawaited(controller.close());
        return;
      }
      final Disposable? watch = watchCancellation((cause) {
        subscription.cancel().ignore();
        controller.addError(cause);
        unawaited(controller.close());
      });
      controller
        ..onPause = subscription.pause
        ..onResume = subscription.resume
        ..onCancel = () {
          watch?.dispose();
          return keepInZone(subscription.cancel());
        };
    }, isBroadcast: isBroadcast);
  }
}
