/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/context/abstract_coroutine_context_element.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_key.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_zone.dart';
import 'package:essentia_coroutines/src/continuation/suspension.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/scheduler/scheduled_task.dart';
import 'package:essentia_coroutines/src/scheduler/system_scheduler.dart';
import 'package:essentia_time/essentia_time.dart';

/// Where time comes from and where delayed work waits: the time source, the
/// clock and the timers of a component, in one place.
///
/// A scheduler is an element of a coroutine context: `delay`, `withTimeout` and
/// `Scheduler.current` use the one of the current context. A component that
/// waits, measures or stamps takes a scheduler, defaulting to [system], and a
/// test hands it a `TestScheduler` or runs inside `runTest`, and time moves on
/// without waiting.
///
/// ```dart
/// Future<void> poll(Scheduler scheduler) async {
///   while (true) {
///     await check();
///     await scheduler.delay(30.seconds);
///   }
/// }
/// ```
abstract class Scheduler with AbstractCoroutineContextElement {
  /// Creates a scheduler.
  const Scheduler();

  /// The scheduler of the running program: `Timer`s, the monotonic time
  /// source and the system clock.
  static const Scheduler system = SystemScheduler();

  /// The key a scheduler is stored under in a coroutine context.
  static const key = CoroutineContextKey<Scheduler>('Scheduler');

  /// The scheduler of the current coroutine context, [system] when it
  /// holds none.
  static Scheduler get current => currentCoroutineContext().get(key) ?? system;

  /// The key a scheduler is stored under.
  @override
  CoroutineContextKey<Scheduler> get contextKey => key;

  /// The time source that measures how long things take.
  TimeSource get timeSource;

  /// The clock that tells the calendar time.
  Clock get clock;

  /// Runs [action] once [delay] has passed.
  ///
  /// A zero or negative [delay] runs it as soon as possible, never
  /// synchronously.
  ///
  /// Returns the task, whose `cancel` calls the action off.
  ScheduledTask schedule(Duration delay, void Function() action);

  /// Waits for [duration].
  ///
  /// The wait is cancellable: inside a cancelled job it ends with the job's
  /// [CancellationException], and its timer is called off. A zero or negative
  /// [duration] does not wait at all.
  ///
  /// Returns a future that completes once [duration] has passed.
  Future<void> delay(Duration duration) {
    if (duration <= Duration.zero) {
      try {
        ensureActive();
      } on CancellationException catch (cause, stackTrace) {
        return Future<void>.error(cause, stackTrace);
      }
      return Future<void>.value();
    }
    return suspendCancellableCoroutine<void>((it) {
      final ScheduledTask task = schedule(duration, () => it.resume(null));
      it.invokeOnCancellation((cause) => task.cancel());
    });
  }
}
