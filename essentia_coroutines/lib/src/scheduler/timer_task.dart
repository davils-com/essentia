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
