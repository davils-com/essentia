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
import 'package:meta/meta.dart';

/// A timer of a `TestScheduler`: an action due at a point of virtual time,
/// once or every [period].
@internal
final class VirtualTimer
    implements Timer, ScheduledTask, Comparable<VirtualTimer> {
  /// Creates the timer running [onFire] at [due], the [sequence]th timer
  /// of its scheduler, which [onCancel] takes out of its queue.
  VirtualTimer({
    required this.due,
    required this.sequence,
    required this.background,
    required this.onFire,
    required this.onCancel,
    this.period,
  });

  /// The virtual time at which the timer fires next.
  Duration due;

  /// The position of the timer among every timer of its scheduler, which
  /// orders timers due at the same time.
  int sequence;

  /// The period of a periodic timer, `null` for a timer that fires once.
  final Duration? period;

  /// Whether the timer belongs to background work.
  final bool background;

  /// What runs when the timer fires.
  final void Function(VirtualTimer timer) onFire;

  /// Takes the timer out of the queue of its scheduler.
  final void Function(VirtualTimer timer) onCancel;

  /// How many times the timer fired.
  var _tick = 0;

  /// Whether the timer fired for good or was cancelled.
  var _done = false;

  /// See [Timer.isActive].
  @override
  bool get isActive => !_done;

  /// See [Timer.tick].
  @override
  int get tick => _tick;

  /// See [Timer.cancel].
  @override
  void cancel() {
    if (_done) {
      return;
    }
    _done = true;
    onCancel(this);
  }

  /// Fires the timer; a timer that fires once is done afterwards.
  void fire() {
    if (_done) {
      return;
    }
    _tick++;
    if (period == null) {
      _done = true;
    }
    onFire(this);
  }

  /// Orders the timer by due time, then by the order the timers were
  /// created in.
  ///
  /// Returns a negative number, zero or a positive number.
  @override
  int compareTo(VirtualTimer other) {
    final int byDue = due.compareTo(other.due);
    if (byDue != 0) {
      return byDue;
    }
    return sequence.compareTo(other.sequence);
  }
}
