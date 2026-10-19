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

import 'package:essentia_coroutines/src/scheduler/scheduled_task.dart';
import 'package:essentia_coroutines/src/scheduler/scheduler.dart';
import 'package:essentia_coroutines/src/scheduler/timer_task.dart';
import 'package:essentia_coroutines/src/scheduler/virtual_time.dart';
import 'package:essentia_time/essentia_time.dart';
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
