/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';
import 'dart:collection';

import 'package:essentia_coroutines/src/context/coroutine_context_zone.dart';
import 'package:essentia_coroutines/src/scheduler/scheduled_task.dart';
import 'package:essentia_coroutines/src/scheduler/scheduler.dart';
import 'package:essentia_coroutines/src/scheduler/virtual_time.dart';
import 'package:essentia_coroutines/src/testing/background_work.dart';
import 'package:essentia_coroutines/src/testing/virtual_timer.dart';
import 'package:essentia_time/essentia_time.dart';
import 'package:meta/meta.dart';

/// A scheduler on virtual time, and the event loop it runs on, Kotlin's
/// `TestCoroutineScheduler`.
///
/// Nothing it schedules runs on its own. A test moves virtual time on with
/// [advanceTimeBy], [runCurrent] or [advanceUntilIdle], and every task that
/// falls due runs at its exact virtual time, in due order. A delay of an
/// hour takes no time at all, and nothing depends on how fast the machine
/// is.
///
/// Code that runs inside the scheduler - in `runTest`, or in [run] - is on
/// a virtual event loop: its microtasks, `Timer`s, `Future.delayed` and
/// `Scheduler.system` are all virtual, and every microtask runs before the
/// next timer, exactly as on the real event loop. Called from inside, the
/// advance methods run synchronously. Called from outside, they also let
/// the real event loop settle between tasks, for work started outside.
///
/// The scheduler is its own [timeSource] and [clock], so a component given
/// the scheduler measures and stamps on the same virtual time it waits on.
///
/// ```dart
/// test('retries after the backoff', () async {
///   final scheduler = TestScheduler();
///   final Future<String> answer = fetchWithRetry(scheduler);
///
///   await scheduler.advanceTimeBy(500.milliseconds);
///
///   expect(await answer, 'ok');
/// });
/// ```
final class TestScheduler extends Scheduler
    implements TimeSource, Clock, VirtualTime {
  /// Creates a scheduler at virtual time zero, whose clock starts at
  /// [start], the Unix epoch unless given.
  TestScheduler({Instant? start}) : start = start ?? Instant.epoch;

  /// The calendar time of virtual time zero.
  final Instant start;

  /// The microtasks of the virtual event loop, oldest first.
  final _microtasks = Queue<void Function()>();

  /// The timers that wait to fire, in due order.
  final _timers = SplayTreeSet<VirtualTimer>();

  /// The current virtual time.
  Duration _now = Duration.zero;

  /// How many timers were created so far.
  var _sequence = 0;

  /// The zone of the virtual event loop, forked on first use.
  Zone? _zone;

  /// What runs whenever work arrives, so a driver waiting for work wakes
  /// up.
  void Function()? _onWork;

  /// The virtual time passed since the scheduler was created, Kotlin's
  /// `currentTime`.
  Duration get currentTime => _now;

  /// How many timers wait to fire.
  int get pendingTasks => _timers.length;

  /// This scheduler, whose reading is the virtual time.
  @override
  TimeSource get timeSource => this;

  /// This scheduler, whose time is [start] plus the virtual time.
  @override
  Clock get clock => this;

  /// The zone of the virtual event loop.
  ///
  /// It is forked from the zone that first asks for it.
  Zone get zone => _zone ??= Zone.current.fork(
    specification: ZoneSpecification(
      scheduleMicrotask: (self, parent, zone, callback) {
        _microtasks.add(zone.bindCallback(callback));
        _onWork?.call();
      },
      createTimer: (self, parent, zone, duration, callback) =>
          _addTimer(duration, zone, zone.bindCallback(callback)),
      createPeriodicTimer: (self, parent, zone, period, callback) {
        final void Function(Timer timer) bound = zone.bindUnaryCallback(
          callback,
        );
        return _addTimer(period, zone, () {}, period: period, periodic: bound);
      },
    ),
    zoneValues: <Object?, Object?>{virtualTimeKey: this},
  );

  /// Reads the virtual time.
  ///
  /// Returns [currentTime].
  @override
  Duration read() => _now;

  /// Marks the current virtual time.
  ///
  /// Returns a mark of this scheduler.
  @override
  TimeMark markNow() => TimeMark(this, _now);

  /// Reads the calendar time on virtual time.
  ///
  /// Returns [start] plus [currentTime].
  @override
  Instant now() => start + _now;

  /// Runs [body] on the virtual event loop of this scheduler.
  ///
  /// Returns what [body] returns.
  R run<R>(R Function() body) => zone.run(body);

  /// Queues [action] to run once virtual time has moved on by [delay], in
  /// the zone it was scheduled from.
  ///
  /// A zero or negative [delay] makes it due now; it runs on the next
  /// [runCurrent].
  ///
  /// Returns the task, whose `cancel` calls the action off.
  @override
  ScheduledTask schedule(Duration delay, void Function() action) =>
      _addTimer(delay, Zone.current, Zone.current.bindCallback(action));

  /// Moves virtual time on by [duration] and runs every task that falls
  /// due on the way, Kotlin's `advanceTimeBy` followed by `runCurrent`.
  ///
  /// Tasks run in due order, at their own virtual time, with the
  /// microtasks they start settled before the next one runs.
  ///
  /// Returns a future that completes once virtual time reached its target;
  /// inside the scheduler it is complete already.
  ///
  /// Throws an [ArgumentError] if [duration] is negative, and the error of
  /// a task that throws.
  Future<void> advanceTimeBy(Duration duration) {
    if (duration.isNegative) {
      return Future<void>.error(
        ArgumentError.value(
          duration,
          'duration',
          'Virtual time never goes backwards',
        ),
      );
    }
    final Duration target = _now + duration;
    if (_isInside) {
      advanceTimeBySync(duration);
      return Future<void>.value();
    }
    return _advanceOutside(target);
  }

  /// Runs every task due at the current virtual time without moving it,
  /// Kotlin's `runCurrent`.
  ///
  /// Returns a future that completes once no task is due any more.
  Future<void> runCurrent() => advanceTimeBy(Duration.zero);

  /// Moves virtual time on until no task waits any more, Kotlin's
  /// `advanceUntilIdle`.
  ///
  /// Timers of the background scope of a test do not keep it going. Work
  /// that keeps scheduling more work never lets it finish.
  ///
  /// Returns a future that completes once nothing is left to run.
  Future<void> advanceUntilIdle() {
    if (_isInside) {
      advanceUntilIdleSync();
      return Future<void>.value();
    }
    return _untilIdleOutside();
  }

  /// Renders the virtual time.
  @override
  String toString() => 'TestScheduler($_now)';

  /// Moves virtual time on by [duration], running what falls due, in the
  /// caller's frame.
  ///
  /// Throws an [ArgumentError] if [duration] is negative.
  @internal
  void advanceTimeBySync(Duration duration) {
    if (duration.isNegative) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Virtual time never goes backwards',
      );
    }
    final Duration target = _now + duration;
    while (step(limit: target)) {}
    if (target > _now) {
      _now = target;
    }
  }

  /// Runs everything until only background timers are left, in the
  /// caller's frame.
  @internal
  void advanceUntilIdleSync() {
    while (_microtasks.isNotEmpty || _timers.any(_isForeground)) {
      step();
    }
  }

  /// Runs one microtask, or the next timer due no later than [limit] when
  /// no microtask waits, moving virtual time to it.
  ///
  /// Returns whether anything ran.
  @internal
  bool step({Duration? limit}) {
    if (_microtasks.isNotEmpty) {
      _microtasks.removeFirst()();
      return true;
    }
    if (_timers.isEmpty) {
      return false;
    }
    final VirtualTimer next = _timers.first;
    if (limit != null && next.due > limit) {
      return false;
    }
    _timers.remove(next);
    if (next.due > _now) {
      _now = next.due;
    }
    next.fire();
    return true;
  }

  /// Whether a microtask of the virtual event loop waits to run.
  @internal
  bool get hasMicrotasks => _microtasks.isNotEmpty;

  /// Whether a timer waits to fire.
  @internal
  bool get hasTimers => _timers.isNotEmpty;

  /// Runs what is due now: every microtask, and the timers due at the
  /// current virtual time.
  @internal
  void runCurrentSync() => advanceTimeBySync(Duration.zero);

  /// Calls [listener] whenever work arrives, or nobody with `null`.
  @internal
  void listenForWork(void Function()? listener) => _onWork = listener;

  /// Drops every timer that waits, calling it off.
  @internal
  void dropTimers() {
    for (final VirtualTimer timer in _timers.toList()) {
      timer.cancel();
    }
  }

  /// Whether the current code runs on the virtual event loop.
  bool get _isInside => identical(Zone.current[virtualTimeKey], this);

  /// Queues a timer due after [delay], created in [zone], running [action]
  /// once or [periodic] every [period].
  ///
  /// Returns the timer.
  VirtualTimer _addTimer(
    Duration delay,
    Zone zone,
    void Function() action, {
    Duration? period,
    void Function(Timer timer)? periodic,
  }) {
    final timer = VirtualTimer(
      due: _now + (delay.isNegative ? Duration.zero : delay),
      sequence: _sequence++,
      background: contextOfZone(zone).get(BackgroundWork.key) != null,
      period: period,
      onFire: (fired) {
        if (periodic == null) {
          action();
          return;
        }
        _reschedule(fired);
        periodic(fired);
      },
      onCancel: _timers.remove,
    );
    _timers.add(timer);
    _onWork?.call();
    return timer;
  }

  /// Queues a periodic [timer] again for its next period.
  void _reschedule(VirtualTimer timer) {
    final Duration? period = timer.period;
    if (period == null) {
      return;
    }
    timer
      ..due = _now + (period > Duration.zero ? period : Duration.zero)
      ..sequence = _sequence++;
    _timers.add(timer);
  }

  /// Whether [timer] belongs to foreground work.
  ///
  /// Returns `true` unless it belongs to the background scope.
  static bool _isForeground(VirtualTimer timer) => !timer.background;

  /// Moves virtual time on to [target] for work started outside the
  /// scheduler, letting the real event loop settle between tasks.
  Future<void> _advanceOutside(Duration target) async {
    await _settle();
    while (_timers.isNotEmpty && _timers.first.due <= target) {
      step(limit: target);
      await _settle();
    }
    if (target > _now) {
      _now = target;
    }
  }

  /// Runs everything until only background timers are left, for work
  /// started outside the scheduler.
  Future<void> _untilIdleOutside() async {
    await _settle();
    while (_microtasks.isNotEmpty || _timers.any(_isForeground)) {
      step();
      await _settle();
    }
  }

  /// Runs every queued microtask of the virtual event loop.
  void _drainMicrotasks() {
    while (_microtasks.isNotEmpty) {
      _microtasks.removeFirst()();
    }
  }

  /// Lets pending microtasks and zero delay timers of the real event loop,
  /// and the virtual microtasks they queue, run.
  ///
  /// Returns a future that completes after them.
  Future<void> _settle() async {
    for (var round = 0; round < _settleRounds; round++) {
      _drainMicrotasks();
      await Future<void>.delayed(Duration.zero);
    }
    _drainMicrotasks();
  }

  /// How many turns of the real event loop [_settle] gives the work.
  static const _settleRounds = 3;
}
