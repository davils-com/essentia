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
