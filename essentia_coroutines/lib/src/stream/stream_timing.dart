/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/scheduler/scheduled_task.dart';
import 'package:essentia_coroutines/src/scheduler/scheduler.dart';
import 'package:essentia_coroutines/src/stream/subscription_cancel.dart';

/// Kotlin's time based `Flow` operators for streams.
///
/// They wait on `Scheduler.current` of the listener, so inside `runTest`
/// they run on virtual time.
extension StreamTiming<T> on Stream<T> {
  /// Emits an element only once [timeout] passed without a newer one,
  /// Kotlin's `debounce`.
  ///
  /// The latest element is always emitted: when this stream ends, a
  /// pending element is emitted at once before the result ends. A zero
  /// [timeout] emits every element at once. Errors are passed on as they
  /// arrive and leave a pending element pending. Pause, resume and cancel
  /// reach this stream.
  ///
  /// ```dart
  /// queries.debounce(300.milliseconds).collect(search);
  /// ```
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  ///
  /// Throws an [ArgumentError] if [timeout] is negative.
  Stream<T> debounce(Duration timeout) {
    if (timeout.isNegative) {
      throw ArgumentError.value(
        timeout,
        'timeout',
        'Debounce timeout should not be negative',
      );
    }
    return Stream<T>.multi((controller) {
      final Scheduler scheduler = Scheduler.current;
      ({T value})? pending;
      ScheduledTask? timer;

      void flush() {
        final latest = pending;
        pending = null;
        if (latest != null) {
          controller.add(latest.value);
        }
      }

      final StreamSubscription<T> subscription = listen(
        (value) {
          timer?.cancel();
          if (timeout == Duration.zero) {
            controller.add(value);
            return;
          }
          pending = (value: value);
          timer = scheduler.schedule(timeout, flush);
        },
        onError: controller.addError,
        onDone: () {
          timer?.cancel();
          flush();
          unawaited(controller.close());
        },
      );
      controller
        ..onPause = subscription.pause
        ..onResume = subscription.resume
        ..onCancel = () {
          timer?.cancel();
          return keepInZone(subscription.cancel());
        };
    }, isBroadcast: isBroadcast);
  }

  /// Emits the latest element of every [period], Kotlin's `sample`.
  ///
  /// The periods start when the listener subscribes. At the end of a
  /// period the latest element that arrived in it, if any, is emitted;
  /// while the listener is paused, it waits for the first period ending
  /// after the listener resumed. The latest element is not emitted when
  /// this stream ends before its period does. Errors are passed on as they
  /// arrive. Cancel reaches this stream.
  ///
  /// ```dart
  /// positions.sample(1.seconds).collect(render);
  /// ```
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  ///
  /// Throws an [ArgumentError] if [period] is not positive.
  Stream<T> sample(Duration period) {
    if (period <= Duration.zero) {
      throw ArgumentError.value(
        period,
        'period',
        'Sample period should be positive',
      );
    }
    return Stream<T>.multi((controller) {
      final Scheduler scheduler = Scheduler.current;
      ({T value})? latest;
      ScheduledTask? ticker;

      void tick() {
        ticker = scheduler.schedule(period, () {
          final sampled = latest;
          if (sampled != null && !controller.isPaused) {
            latest = null;
            controller.add(sampled.value);
          }
          tick();
        });
      }

      final StreamSubscription<T> subscription = listen(
        (value) => latest = (value: value),
        onError: controller.addError,
        onDone: () {
          ticker?.cancel();
          unawaited(controller.close());
        },
      );
      tick();
      controller.onCancel = () {
        ticker?.cancel();
        return keepInZone(subscription.cancel());
      };
    }, isBroadcast: isBroadcast);
  }
}
