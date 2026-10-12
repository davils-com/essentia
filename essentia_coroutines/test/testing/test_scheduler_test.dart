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
import 'package:essentia_time/essentia_time.dart';
import 'package:test/test.dart';

/// Covers the scheduler on virtual time, driven from outside its zone with
/// awaited advances and from inside it, where the advances run at once:
/// running due tasks in order, cancellable delays, the virtual event loop,
/// and its time source and clock.
void main() {
  group('driven from outside', () {
    test('starts at virtual time zero on the Unix epoch', () {
      final scheduler = TestScheduler();

      expect(scheduler.currentTime, Duration.zero);
      expect(scheduler.now(), Instant.epoch);
      expect(scheduler.pendingTasks, 0);
    });

    test('runs nothing until virtual time moves on', () async {
      final scheduler = TestScheduler();
      final log = <String>[];
      scheduler.schedule(1.seconds, () => log.add('ran'));
      await Future<void>.delayed(Duration.zero);

      final before = List<String>.of(log);
      await scheduler.advanceTimeBy(1.seconds);

      expect(before, isEmpty);
      expect(log, <String>['ran']);
    });

    test('runs due tasks in due order at their own virtual time', () async {
      final scheduler = TestScheduler();
      final log = <String>[];
      scheduler
        ..schedule(
          3.seconds,
          () => log.add('third at ${scheduler.currentTime}'),
        )
        ..schedule(
          1.seconds,
          () => log.add('first at ${scheduler.currentTime}'),
        )
        ..schedule(
          2.seconds,
          () => log.add('second at ${scheduler.currentTime}'),
        );

      await scheduler.advanceTimeBy(5.seconds);

      expect(log, <String>[
        'first at 0:00:01.000000',
        'second at 0:00:02.000000',
        'third at 0:00:03.000000',
      ]);
      expect(scheduler.currentTime, 5.seconds);
    });

    test('runs tasks due at the same time in the order given', () async {
      final scheduler = TestScheduler();
      final log = <int>[];
      for (var index = 0; index < 3; index++) {
        scheduler.schedule(1.seconds, () => log.add(index));
      }

      await scheduler.advanceTimeBy(1.seconds);

      expect(log, <int>[0, 1, 2]);
    });

    test('leaves tasks due later than the target waiting', () async {
      final scheduler = TestScheduler();
      final log = <String>[];
      scheduler.schedule(2.seconds, () => log.add('ran'));

      await scheduler.advanceTimeBy(1.seconds);

      expect(log, isEmpty);
      expect(scheduler.pendingTasks, 1);
    });

    test('runs a task that a task scheduled once it falls due', () async {
      final scheduler = TestScheduler();
      final log = <Duration>[];
      scheduler.schedule(1.seconds, () {
        log.add(scheduler.currentTime);
        scheduler.schedule(1.seconds, () => log.add(scheduler.currentTime));
      });

      await scheduler.advanceTimeBy(2.seconds);

      expect(log, <Duration>[1.seconds, 2.seconds]);
    });

    test('never runs a cancelled task', () async {
      final scheduler = TestScheduler();
      final log = <String>[];
      final ScheduledTask task = scheduler.schedule(
        1.seconds,
        () => log.add('ran'),
      )..cancel();

      await scheduler.advanceTimeBy(1.seconds);
      task.cancel();

      expect(task.isActive, isFalse);
      expect(log, isEmpty);
      expect(scheduler.pendingTasks, 0);
    });

    test('makes a task with a negative delay due now', () async {
      final scheduler = TestScheduler();
      final log = <String>[];
      final ScheduledTask task = scheduler.schedule(
        -1.seconds,
        () => log.add('ran'),
      );

      await scheduler.runCurrent();

      expect(log, <String>['ran']);
      expect(task.isActive, isFalse);
      expect(scheduler.currentTime, Duration.zero);
    });

    test('refuses to move virtual time backwards', () async {
      final scheduler = TestScheduler();

      await expectLater(
        scheduler.advanceTimeBy(-1.seconds),
        throwsArgumentError,
      );
    });

    test('moves on until nothing is left to run', () async {
      final scheduler = TestScheduler();
      final log = <Duration>[];
      scheduler
        ..schedule(1.minutes, () => log.add(scheduler.currentTime))
        ..schedule(1.hours, () => log.add(scheduler.currentTime));

      await scheduler.advanceUntilIdle();

      expect(log, <Duration>[1.minutes, 1.hours]);
      expect(scheduler.currentTime, 1.hours);
    });

    test('ends a delay once virtual time reaches it', () async {
      final scheduler = TestScheduler();
      var done = false;
      unawaited(scheduler.delay(1.hours).then((_) => done = true));

      await scheduler.advanceTimeBy(59.minutes);
      final early = done;
      await scheduler.advanceTimeBy(1.minutes);

      expect(early, isFalse);
      expect(done, isTrue);
    });

    test('lets asynchronous work reach its next delay between tasks', () async {
      final scheduler = TestScheduler();
      final log = <Duration>[];
      Future<void> poll() async {
        for (var round = 0; round < 3; round++) {
          await scheduler.delay(10.seconds);
          log.add(scheduler.currentTime);
        }
      }

      final Future<void> polling = poll();
      await scheduler.advanceTimeBy(30.seconds);
      await polling;

      expect(log, <Duration>[10.seconds, 20.seconds, 30.seconds]);
    });

    test('runs work started on its event loop from outside', () async {
      final scheduler = TestScheduler();
      final log = <String>[];
      final Future<void> work = scheduler.run(() async {
        log.add('started');
        await Future<void>.delayed(1.seconds);
        log.add('after a second at ${scheduler.currentTime}');
        scheduleMicrotask(() => log.add('microtask'));
        await Future<void>.delayed(1.seconds);
        log.add('done');
      });

      var finished = false;
      unawaited(work.then((_) => finished = true));

      await scheduler.advanceTimeBy(1.seconds);
      final afterOne = List<String>.of(log);
      await scheduler.advanceUntilIdle();

      expect(finished, isTrue);

      expect(afterOne, <String>[
        'started',
        'after a second at 0:00:01.000000',
        'microtask',
      ]);
      expect(log.last, 'done');
      expect(scheduler.currentTime, 2.seconds);
    });

    test('ends a delay without waiting when it is not positive', () async {
      final scheduler = TestScheduler();

      await scheduler.delay(Duration.zero);
      await scheduler.delay(-1.seconds);

      expect(scheduler.pendingTasks, 0);
    });

    test('ends a delay with the cause when its job is cancelled', () async {
      final scheduler = TestScheduler();
      final scope = CoroutineScope(Job());
      final Deferred<void> waiting = scope.async(
        (it) => scheduler.delay(1.hours),
        start: CoroutineStart.undispatched,
      );

      scope.cancel(const CancellationException('stop'));

      await expectLater(
        waiting,
        throwsA(
          isA<CancellationException>().having(
            (error) => error.message,
            'message',
            'stop',
          ),
        ),
      );
      expect(scheduler.pendingTasks, 0);
    });

    test('refuses to start a delay inside a cancelled job', () async {
      final scheduler = TestScheduler();
      final scope = CoroutineScope(Job()..cancel());
      final Deferred<void> waiting = scope.async(
        (it) => scheduler.delay(1.hours),
        start: CoroutineStart.undispatched,
      );
      final Deferred<void> waitingZero = scope.async(
        (it) => scheduler.delay(Duration.zero),
        start: CoroutineStart.undispatched,
      );

      await expectLater(waiting, throwsA(isA<CancellationException>()));
      await expectLater(waitingZero, throwsA(isA<CancellationException>()));
      expect(scheduler.pendingTasks, 0);
    });

    test('stops listening to the job once the delay ended', () async {
      final scheduler = TestScheduler();
      final job = Job();
      final Deferred<void> waiting = CoroutineScope(job).async(
        (it) => scheduler.delay(1.seconds),
        start: CoroutineStart.undispatched,
      );

      await scheduler.advanceTimeBy(1.seconds);
      await waiting;
      job.cancel();

      expect(waiting.isCancelled, isFalse);
      expect(job.isCancelled, isTrue);
    });
  });

  group('driven from inside', () {
    test('advances synchronously with an already complete future', () {
      final scheduler = TestScheduler();
      final log = <String>[];

      scheduler.run(() {
        scheduler.schedule(1.seconds, () => log.add('ran'));
        final Future<void> advanced = scheduler.advanceTimeBy(2.seconds);
        log.add('returned');
        unawaited(advanced);
      });

      expect(log, <String>['ran', 'returned']);
      expect(scheduler.currentTime, 2.seconds);
    });

    test('keeps microtasks on the virtual event loop', () {
      final scheduler = TestScheduler();
      final log = <String>[];

      scheduler.run(() {
        scheduleMicrotask(() => log.add('microtask'));
        log.add('queued');
      });
      final before = List<String>.of(log);
      scheduler.run(() => unawaited(scheduler.runCurrent()));

      expect(before, <String>['queued']);
      expect(log, <String>['queued', 'microtask']);
    });

    test('makes raw timers and Future.delayed virtual', () {
      final scheduler = TestScheduler();
      final log = <String>[];

      scheduler.run(() {
        Timer(1.hours, () => log.add('timer at ${scheduler.currentTime}'));
        unawaited(
          Future<void>.delayed(
            30.minutes,
            () => log.add('delayed at ${scheduler.currentTime}'),
          ),
        );
        unawaited(scheduler.advanceUntilIdle());
      });

      expect(log, <String>[
        'delayed at 0:30:00.000000',
        'timer at 1:00:00.000000',
      ]);
      expect(scheduler.pendingTasks, 0);
    });

    test('fires periodic timers at every period until cancelled', () {
      final scheduler = TestScheduler();
      final ticks = <String>[];

      scheduler.run(() {
        Timer.periodic(10.seconds, (timer) {
          ticks.add('${timer.tick} at ${scheduler.currentTime}');
          if (timer.tick == 3) {
            timer.cancel();
          }
        });
        unawaited(scheduler.advanceTimeBy(1.minutes));
      });

      expect(ticks, <String>[
        '1 at 0:00:10.000000',
        '2 at 0:00:20.000000',
        '3 at 0:00:30.000000',
      ]);
      expect(scheduler.pendingTasks, 0);
    });

    test('fires a periodic timer with a zero period once per step', () {
      final scheduler = TestScheduler();
      var ticks = 0;
      final Timer timer = scheduler.run(
        () => Timer.periodic(Duration.zero, (timer) => ticks++),
      );

      final steps = <bool>[scheduler.step(), scheduler.step()];
      timer.cancel();

      expect(steps, <bool>[true, true]);
      expect(ticks, 2);
      expect(scheduler.step(), isFalse);
      expect(scheduler.currentTime, Duration.zero);
    });

    test('runs a microtask before the next timer', () {
      final scheduler = TestScheduler();
      final log = <String>[];

      scheduler.run(() {
        Timer(Duration.zero, () => log.add('timer'));
        scheduleMicrotask(() => log.add('microtask'));
        unawaited(scheduler.runCurrent());
      });

      expect(log, <String>['microtask', 'timer']);
    });

    test('refuses to move virtual time backwards', () async {
      final scheduler = TestScheduler();
      final Future<void> refused = scheduler.run(
        () => scheduler.advanceTimeBy(-1.seconds),
      );
      final Future<void> checked = expectLater(refused, throwsArgumentError);

      await scheduler.runCurrent();

      await checked;
      expect(
        () => scheduler.run(() => scheduler.advanceTimeBySync(-1.seconds)),
        throwsArgumentError,
      );
    });

    test('measures a timer as active until it fires', () {
      final scheduler = TestScheduler();

      final Timer timer = scheduler.run(() => Timer(1.seconds, () {}));
      final bool waiting = timer.isActive;
      scheduler.run(() => unawaited(scheduler.advanceTimeBy(1.seconds)));

      expect(waiting, isTrue);
      expect(timer.isActive, isFalse);
      expect(timer.tick, 1);
    });
  });

  group('time source and clock', () {
    test('is its own time source, reading virtual time', () async {
      final scheduler = TestScheduler();
      final TimeMark start = scheduler.timeSource.markNow();

      await scheduler.advanceTimeBy(90.seconds);

      expect(start.elapsedNow(), 90.seconds);
      expect(scheduler.timeSource, same(scheduler));
      expect(scheduler.read(), 90.seconds);
    });

    test('is its own clock, starting where it was told', () async {
      final scheduler = TestScheduler(
        start: Instant.parse('2026-10-07T12:00:00Z'),
      );

      await scheduler.advanceTimeBy(30.minutes);

      expect(scheduler.clock, same(scheduler));
      expect(scheduler.clock.now(), Instant.parse('2026-10-07T12:30:00Z'));
    });

    test('starts its clock at the epoch unless told otherwise', () {
      expect(TestScheduler().start, Instant.epoch);
    });

    test('lends its time to the system scheduler inside', () {
      final scheduler = TestScheduler(
        start: Instant.parse('2026-01-01T00:00Z'),
      );

      final (TimeSource source, Clock clock) = scheduler.run(
        () => (Scheduler.system.timeSource, Scheduler.system.clock),
      );

      expect(source, same(scheduler));
      expect(clock, same(scheduler));
    });

    test('renders its virtual time', () {
      expect(TestScheduler().toString(), 'TestScheduler(0:00:00.000000)');
    });
  });
}
