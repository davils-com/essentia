/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/coroutines/scheduled_task.dart';
import 'package:essentia/src/coroutines/scheduler.dart';
import 'package:essentia/src/coroutines/timer_task.dart';
import 'package:essentia/src/coroutines/virtual_time.dart';
import 'package:essentia/src/time/clock.dart';
import 'package:essentia/src/time/time_source.dart';
import 'package:meta/meta.dart';

/// The scheduler behind `Scheduler.system`: `Timer`s of the current zone,
/// `TimeSource.monotonic` and `Clock.system`.
///
/// Inside the virtual time of a `TestScheduler` - in `runTest` or
/// `TestScheduler.run` - it reads that scheduler's time source and clock,
/// and its timers are virtual, so a component left on the system scheduler
/// is tested on virtual time as well.
final class SystemScheduler extends Scheduler {
  /// Creates the system scheduler.
  ///
  /// There is one, `Scheduler.system`; nothing else creates another.
  @internal
  const SystemScheduler();

  /// The monotonic time source of the running program, or the virtual one
  /// of the enclosing virtual time.
  @override
  TimeSource get timeSource =>
      ambientVirtualTime()?.timeSource ?? TimeSource.monotonic;

  /// The clock of the system, or the virtual one of the enclosing virtual
  /// time.
  @override
  Clock get clock => ambientVirtualTime()?.clock ?? Clock.system;

  /// Runs [action] on a `Timer` once [delay] has passed.
  ///
  /// Returns the task wrapping the timer.
  @override
  ScheduledTask schedule(Duration delay, void Function() action) =>
      TimerTask(Timer(delay, action));

  /// Names the scheduler.
  @override
  String toString() => 'Scheduler(system)';
}
