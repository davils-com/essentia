/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/essentia.dart';
import 'package:essentia/testing.dart';
import 'package:test/test.dart';

/// Lets every pending microtask and zero delay timer run.
///
/// Returns a future that completes after them.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

/// Covers the counting semaphore: permits, fair and unfair waiting,
/// resizing, timeouts and cancellation.
void main() {
  test('refuses a negative number of permits', () {
    expect(() => Semaphore(-1), throwsRangeError);
  });

  test('admits nobody with zero permits until it is resized', () async {
    final semaphore = Semaphore(0);
    var acquired = false;
    final bool tried = semaphore.tryAcquire();
    unawaited(semaphore.acquire().then((_) => acquired = true));
    await _settle();
    final early = acquired;

    semaphore.resize(1);
    await _settle();

    expect(tried, isFalse);
    expect(early, isFalse);
    expect(acquired, isTrue);
    expect(semaphore.availablePermits, 0);
  });

  test('applies a change of fairness to later acquirers', () async {
    final semaphore = Semaphore(1)..tryAcquire();
    unawaited(semaphore.acquire());
    await _settle();
    final bool fairTry = semaphore.tryAcquire();

    semaphore
      ..fair = false
      ..resize(2);
    final bool unfairTry = semaphore.tryAcquire();

    expect(fairTry, isFalse);
    expect(unfairTry, isTrue);
  });

  test('refuses acquired permits outside zero to its permits', () {
    expect(() => Semaphore(2, acquiredPermits: -1), throwsRangeError);
    expect(() => Semaphore(2, acquiredPermits: 3), throwsRangeError);
  });

  test('starts with its acquired permits taken', () {
    final semaphore = Semaphore(3, acquiredPermits: 2);

    expect(semaphore.permits, 3);
    expect(semaphore.availablePermits, 1);
    expect(semaphore.fair, isTrue);
    expect(semaphore.toString(), 'Semaphore(1 of 3 free, 0 waiting)');
  });

  test('takes free permits without waiting until none is left', () {
    final semaphore = Semaphore(2);

    final taken = <bool>[
      semaphore.tryAcquire(),
      semaphore.tryAcquire(),
      semaphore.tryAcquire(),
    ];

    expect(taken, <bool>[true, true, false]);
    expect(semaphore.availablePermits, 0);
  });

  test('refuses to give back more permits than were taken', () {
    final semaphore = Semaphore(1);

    expect(semaphore.release, throwsStateError);
  });

  test('lets an acquirer wait until a permit is given back', () async {
    final semaphore = Semaphore(1)..tryAcquire();
    var acquired = false;
    unawaited(semaphore.acquire().then((_) => acquired = true));
    await _settle();
    final early = acquired;
    final int waiting = semaphore.waitingCount;

    semaphore.release();
    await _settle();

    expect(early, isFalse);
    expect(waiting, 1);
    expect(acquired, isTrue);
    expect(semaphore.availablePermits, 0);
  });

  test('serves waiters oldest first', () async {
    final semaphore = Semaphore(1);
    final holding = Completer<void>();
    final log = <int>[];
    final Future<void> held = semaphore.withPermit(() => holding.future);
    final waiting = <Future<void>>[
      for (var index = 0; index < 3; index++)
        semaphore.withPermit(() => log.add(index)),
    ];
    await _settle();

    holding.complete();
    await Future.wait(<Future<void>>[held, ...waiting]);

    expect(log, <int>[0, 1, 2]);
  });

  test('never lets a newcomer overtake a waiter', () async {
    final semaphore = Semaphore(1)..tryAcquire();
    unawaited(semaphore.acquire());
    await _settle();

    semaphore.release();

    expect(semaphore.tryAcquire(), isFalse);
  });

  test('refuses a newcomer while anybody waits when fair', () async {
    final semaphore = Semaphore(2, acquiredPermits: 2);
    unawaited(semaphore.acquire());
    await _settle();
    semaphore.resize(2);

    expect(semaphore.tryAcquire(), isFalse);
  });

  test('gives the permit back when the action fails', () async {
    final semaphore = Semaphore(1);

    final Future<void> failed = semaphore.withPermit(
      () => Future<void>.error(const FormatException()),
    );

    await expectLater(failed, throwsFormatException);
    expect(semaphore.availablePermits, 1);
  });

  test('runs up to its permits at once', () async {
    final semaphore = Semaphore(2);
    final holding = Completer<void>();
    var running = 0;
    final actions = <Future<void>>[
      for (var index = 0; index < 3; index++)
        semaphore.withPermit(() async {
          running++;
          await holding.future;
        }),
    ];
    await _settle();

    final runningAtOnce = running;
    holding.complete();
    await Future.wait(actions);

    expect(runningAtOnce, 2);
    expect(running, 3);
    expect(semaphore.availablePermits, 2);
  });

  group('an unfair semaphore', () {
    test('lets a newcomer take a permit before the woken waiter', () async {
      final semaphore = Semaphore(1, fair: false)..tryAcquire();
      var waiterAcquired = false;
      unawaited(semaphore.acquire().then((_) => waiterAcquired = true));
      await _settle();

      semaphore.release();
      final bool newcomer = semaphore.tryAcquire();
      await _settle();

      expect(semaphore.fair, isFalse);
      expect(newcomer, isTrue);
      expect(waiterAcquired, isFalse);
      expect(semaphore.waitingCount, 1);
    });

    test('hands a free permit to the oldest waiter later', () async {
      final semaphore = Semaphore(1, fair: false)..tryAcquire();
      final log = <int>[];
      unawaited(semaphore.acquire().then((_) => log.add(0)));
      unawaited(semaphore.acquire().then((_) => log.add(1)));
      await _settle();

      semaphore
        ..release()
        ..resize(1);
      await _settle();
      semaphore.release();
      await _settle();

      expect(log, <int>[0, 1]);
      expect(semaphore.availablePermits, 0);
    });

    test('lets a newcomer take a free permit while others wait', () async {
      final semaphore = Semaphore(1, fair: false)..tryAcquire();
      unawaited(semaphore.acquire());
      await _settle();

      semaphore.resize(2);

      expect(semaphore.tryAcquire(), isTrue);
    });
  });

  group('resizing', () {
    test('hands new permits to the waiters at once', () async {
      final semaphore = Semaphore(1)..tryAcquire();
      final log = <int>[];
      unawaited(semaphore.acquire().then((_) => log.add(0)));
      unawaited(semaphore.acquire().then((_) => log.add(1)));
      await _settle();

      semaphore.resize(3);
      await _settle();

      expect(log, <int>[0, 1]);
      expect(semaphore.permits, 3);
      expect(semaphore.availablePermits, 0);
    });

    test('takes nothing away from the holders when shrunk', () async {
      final semaphore = Semaphore(3)
        ..tryAcquire()
        ..tryAcquire()
        ..tryAcquire()
        ..resize(1);
      var acquired = false;
      unawaited(semaphore.acquire().then((_) => acquired = true));

      semaphore
        ..release()
        ..release();
      await _settle();
      final early = acquired;
      semaphore.release();
      await _settle();

      expect(early, isFalse);
      expect(acquired, isTrue);
      expect(semaphore.availablePermits, 0);
    });

    test('never reports fewer than zero free permits', () {
      final semaphore = Semaphore(2)
        ..tryAcquire()
        ..tryAcquire()
        ..resize(0);

      expect(semaphore.availablePermits, 0);
      expect(semaphore.tryAcquire(), isFalse);
      expect(semaphore.toString(), 'Semaphore(0 of 0 free, 0 waiting)');
    });

    test('refuses a negative number of permits', () {
      expect(() => Semaphore(1).resize(-1), throwsRangeError);
    });
  });

  group('a wait with a timeout', () {
    test('takes a free permit at once', () async {
      final semaphore = Semaphore(1);

      final bool acquired = await semaphore.tryAcquireWithin(
        1.seconds,
        scheduler: TestScheduler(),
      );

      expect(acquired, isTrue);
    });

    test('does not wait at all for a zero timeout', () async {
      final semaphore = Semaphore(1)..tryAcquire();

      final bool acquired = await semaphore.tryAcquireWithin(Duration.zero);

      expect(acquired, isFalse);
      expect(semaphore.waitingCount, 0);
    });

    test('takes a permit given back in time', () async {
      final scheduler = TestScheduler();
      final semaphore = Semaphore(1)..tryAcquire();
      final Future<bool> acquiring = semaphore.tryAcquireWithin(
        2.seconds,
        scheduler: scheduler,
      );

      await scheduler.advanceTimeBy(1.seconds);
      semaphore.release();

      expect(await acquiring, isTrue);
      expect(scheduler.pendingTasks, 0);
    });

    test('gives up and leaves the queue once the timeout passes', () async {
      final scheduler = TestScheduler();
      final semaphore = Semaphore(1)..tryAcquire();
      final Future<bool> acquiring = semaphore.tryAcquireWithin(
        2.seconds,
        scheduler: scheduler,
      );

      await scheduler.advanceTimeBy(2.seconds);
      final bool acquired = await acquiring;
      semaphore.release();

      expect(acquired, isFalse);
      expect(semaphore.waitingCount, 0);
      expect(semaphore.availablePermits, 1);
    });

    test(
      'waits on the virtual time of the test by default',
      () => runTest((it) async {
        final semaphore = Semaphore(1)..tryAcquire();
        it.launch((it) async {
          await delay(3.seconds);
          semaphore.release();
        });

        final bool late = await semaphore.tryAcquireWithin(2.seconds);
        final Duration gaveUpAt = it.currentTime;
        final bool inTime = await semaphore.tryAcquireWithin(2.seconds);

        expect(late, isFalse);
        expect(gaveUpAt, 2.seconds);
        expect(inTime, isTrue);
        expect(it.currentTime, 3.seconds);
      }),
    );

    test(
      'calls its deadline off when cancelled',
      () => runTest((it) async {
        final semaphore = Semaphore(1)..tryAcquire();
        final Deferred<bool> acquiring = it.async(
          (it) => semaphore.tryAcquireWithin(1.hours),
        );
        it.runCurrent();
        final int pending = it.testScheduler.pendingTasks;

        acquiring.cancel();
        it.runCurrent();

        expect(pending, 1);
        expect(it.testScheduler.pendingTasks, 0);
        expect(semaphore.waitingCount, 0);
        await expectLater(acquiring, throwsA(isA<CancellationException>()));
      }),
    );
  });

  group('cancellation', () {
    test(
      'refuses to wait inside a cancelled job',
      () => runTest((it) async {
        final semaphore = Semaphore(1);
        final Deferred<void> acquiring = it.async((it) {
          it.cancel();
          return semaphore.acquire();
        });

        await expectLater(acquiring, throwsA(isA<CancellationException>()));
        expect(semaphore.availablePermits, 1);
      }),
    );

    test(
      'stops a waiter whose job is cancelled',
      () => runTest((it) async {
        final semaphore = Semaphore(1)..tryAcquire();
        final Deferred<void> acquiring = it.async((it) => semaphore.acquire());
        it.runCurrent();

        acquiring.cancel();

        await expectLater(acquiring, throwsA(isA<CancellationException>()));
        expect(semaphore.waitingCount, 0);
      }),
    );

    test(
      'passes a permit on past a cancelled waiter',
      () => runTest((it) async {
        final semaphore = Semaphore(1)..tryAcquire();
        final Deferred<void> cancelled = it.async((it) => semaphore.acquire());
        final Deferred<void> next = it.async((it) => semaphore.acquire());
        it.runCurrent();

        cancelled.cancel();
        semaphore.release();
        await next;

        await expectLater(cancelled, throwsA(isA<CancellationException>()));
        expect(semaphore.availablePermits, 0);
      }),
    );

    test(
      'gives back a permit handed over just before the cancel',
      () => runTest((it) async {
        final semaphore = Semaphore(1)..tryAcquire();
        final Deferred<void> acquiring = it.async((it) => semaphore.acquire());
        it.runCurrent();

        semaphore.release();
        acquiring.cancel();

        await expectLater(acquiring, throwsA(isA<CancellationException>()));
        expect(semaphore.availablePermits, 1);
      }),
    );

    test(
      'keeps the permit once it was taken',
      () => runTest((it) {
        final semaphore = Semaphore(1);
        final Job holder = it.launch((it) async {
          await semaphore.acquire();
          await awaitCancellation();
        });
        it.runCurrent();

        holder.cancel();
        it.runCurrent();

        expect(semaphore.availablePermits, 0);
      }),
    );

    test(
      'gives the permit back from a cancelled withPermit',
      () => runTest((it) async {
        final semaphore = Semaphore(1);
        final Job holder = it.launch(
          (it) => semaphore.withPermit(awaitCancellation),
        );
        it.runCurrent();
        final int held = semaphore.availablePermits;

        await holder.cancelAndJoin();

        expect(held, 0);
        expect(semaphore.availablePermits, 1);
      }),
    );
  });
}
