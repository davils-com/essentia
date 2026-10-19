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
import 'package:meta/meta.dart';

/// A task of the system scheduler, a `Timer` behind the [ScheduledTask]
/// contract.
@internal
final class TimerTask implements ScheduledTask {
  /// Creates the task of [_timer].
  TimerTask(this._timer);

  /// The timer that runs the action.
  final Timer _timer;

  /// Whether the timer still waits to fire.
  @override
  bool get isActive => _timer.isActive;

  /// Cancels the timer.
  @override
  void cancel() => _timer.cancel();
}
