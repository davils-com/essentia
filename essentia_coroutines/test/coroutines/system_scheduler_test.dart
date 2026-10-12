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
import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_coroutines/testing.dart';
import 'package:essentia_time/essentia_time.dart';
import 'package:test/test.dart';

/// Covers the scheduler of the running program, on real time and inside
/// the virtual time of a test.
void main() {
  test('measures on the monotonic time source and the system clock', () {
    expect(Scheduler.system.timeSource, same(TimeSource.monotonic));
    expect(Scheduler.system.clock, same(Clock.system));
  });

  test('is the scheduler of a context without one', () {
    expect(Scheduler.current, same(Scheduler.system));
    expect(Scheduler.system.contextKey, same(Scheduler.key));
  });

  test('runs a scheduled action on a timer', () async {
    final ran = Completer<void>();

    final ScheduledTask task = Scheduler.system.schedule(
      Duration.zero,
      ran.complete,
    );
    final bool waiting = task.isActive;
    await ran.future;

    expect(waiting, isTrue);
    expect(task.isActive, isFalse);
  });

  test('never runs a cancelled action', () async {
    final log = <String>[];
    final ScheduledTask task = Scheduler.system.schedule(
      Duration.zero,
      () => log.add('ran'),
    )..cancel();

    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(log, isEmpty);
    expect(task.isActive, isFalse);
  });

  test(
    'waits on virtual timers inside the virtual time of a test',
    () => runTest((it) async {
      await Scheduler.system.delay(1.hours);

      expect(it.currentTime, 1.hours);
    }),
  );

  test(
    'reads the virtual time and clock inside a test',
    () => runTest((it) async {
      final TimeMark start = Scheduler.system.timeSource.markNow();
      final Instant before = Scheduler.system.clock.now();

      await delay(90.seconds);

      expect(start.elapsedNow(), 90.seconds);
      expect(Scheduler.system.clock.now().difference(before), 90.seconds);
      expect(before, Instant.epoch);
    }),
  );

  test('names itself', () {
    expect(Scheduler.system.toString(), 'Scheduler(system)');
  });
}
