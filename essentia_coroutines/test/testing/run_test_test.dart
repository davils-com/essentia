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
import 'package:test/test.dart';

/// Covers `runTest`: skipping delays on virtual time, the virtual event
/// loop of raw timers, moving time by hand, the background scope, the
/// failures that fail a test, and the real time out.
void main() {
  group('virtual time', () {
    test(
      'skips a delay without waiting for it',
      () => runTest((it) async {
        await delay(1.hours);

        expect(it.currentTime, 1.hours);
        expect(it.testTimeSource.read(), 1.hours);
      }),
    );

    test(
      'makes raw timers and Future.delayed virtual',
      () => runTest((it) async {
        final log = <String>[];
        Timer(2.seconds, () => log.add('timer at ${it.currentTime}'));
        final delayed = Future<void>.delayed(
          1.seconds,
          () => log.add('delayed at ${it.currentTime}'),
        );

        await delayed;
        await delay(5.seconds);

        expect(log, <String>[
          'delayed at 0:00:01.000000',
          'timer at 0:00:02.000000',
        ]);
      }),
    );

    test(
      'makes periodic timers virtual',
      () => runTest((it) async {
        final ticks = <Duration>[];
        final timer = Timer.periodic(
          1.minutes,
          (timer) => ticks.add(it.currentTime),
        );

        await delay(190.seconds);
        timer.cancel();

        expect(ticks, <Duration>[1.minutes, 2.minutes, 3.minutes]);
      }),
    );

    test(
      'moves time on by hand, synchronously',
      () => runTest((it) {
        final log = <String>[];
        it
          ..launch((it) async {
            log.add('started');
            await delay(1.seconds);
            log.add('one');
            await delay(1.seconds);
            log.add('two');
          })
          ..runCurrent();
        final current = List<String>.of(log);
        it.advanceTimeBy(1.seconds);
        final afterOne = List<String>.of(log);
        it.advanceUntilIdle();

        expect(current, <String>['started']);
        expect(afterOne, <String>['started', 'one']);
        expect(log, <String>['started', 'one', 'two']);
        expect(it.currentTime, 2.seconds);
      }),
    );

    test('runs a synchronous body', () {
      final log = <String>[];

      return runTest((it) => log.add('ran')).then((_) {
        expect(log, <String>['ran']);
      });
    });

    test('wakes up as soon as work from real time completes the body', () {
      final arrived = Completer<String>();
      Timer(Duration.zero, () => arrived.complete('real'));

      return runTest((it) async {
        expect(await arrived.future, 'real');
        expect(it.currentTime, Duration.zero);
      });
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('wakes up when work from real time queues virtual work', () {
      final arrived = Completer<String>();
      Timer(Duration.zero, () => arrived.complete('real'));

      return runTest((it) async {
        final String value = await arrived.future;
        await delay(1.seconds);

        expect(value, 'real');
        expect(it.currentTime, 1.seconds);
      });
    }, timeout: const Timeout(Duration(seconds: 10)));

    test(
      'lets the real event loop run during a long virtual test',
      () => runTest((it) async {
        for (var round = 0; round < 3000; round++) {
          await Future<void>.delayed(Duration.zero);
        }

        expect(it.currentTime, Duration.zero);
      }),
    );

    test('uses a scheduler or a test dispatcher it is given', () async {
      final scheduler = TestScheduler();
      final seen = <TestScheduler>[];

      await runTest((it) => seen.add(it.testScheduler), context: scheduler);
      await runTest(
        (it) => seen.add(it.testScheduler),
        context: StandardTestDispatcher(scheduler: scheduler),
      );

      expect(seen, <TestScheduler>[scheduler, scheduler]);
    });

    test(
      'lays the context it is given over the test',
      () => runTest((it) {
        expect(
          currentCoroutineContext().get(CoroutineName.key),
          const CoroutineName('named'),
        );
        expect(it.toString(), 'TestScope[named](active)');
      }, context: const CoroutineName('named')),
    );
  });

  group('the background scope', () {
    test(
      'is marked as background work',
      () => runTest((it) {
        expect(
          '${it.backgroundScope.coroutineContext}',
          contains('BackgroundWork'),
        );
      }),
    );

    test('is cancelled once the body is done', () async {
      final jobs = <Job>[];

      await runTest((it) async {
        jobs.add(it.backgroundScope.launch((it) => awaitCancellation()));
        await delay(1.seconds);
      });

      expect(jobs.single.isCancelled, isTrue);
    });

    test(
      'runs alongside the body on virtual time',
      () => runTest((it) async {
        var ticks = 0;
        it.backgroundScope.launch((it) async {
          while (true) {
            await delay(1.seconds);
            ticks++;
          }
        });

        await delay(3500.milliseconds);

        expect(ticks, 3);
      }),
    );

    test(
      'does not keep advanceUntilIdle going with its timers',
      () => runTest((it) {
        var ticks = 0;
        it.backgroundScope.launch((it) async {
          while (true) {
            await delay(1.seconds);
            ticks++;
          }
        });

        it.advanceUntilIdle();

        expect(ticks, 0);
        expect(it.currentTime, Duration.zero);
      }),
    );

    test('fails the test with its failures', () async {
      final failure = StateError('background');

      await expectLater(
        runTest((it) async {
          it.backgroundScope.launch((it) async {
            await delay(1.seconds);
            throw failure;
          });
          await delay(2.seconds);
        }),
        throwsA(same(failure)),
      );
    });
  });

  test('drops the timers left once the test is done', () async {
    final timers = <Timer>[];

    await runTest((it) => timers.add(Timer(1.hours, () {})));

    expect(timers.single.isActive, isFalse);
  });

  group('a failing test', () {
    test('fails with the failure of the body', () async {
      await expectLater(
        runTest((it) => throw const FormatException('body')),
        throwsFormatException,
      );
    });

    test('fails with the failure of a child', () async {
      final failure = StateError('child');

      await expectLater(
        runTest((it) async {
          it.launch((it) async {
            await delay(1.seconds);
            throw failure;
          });
          await delay(1.hours);
        }),
        throwsA(same(failure)),
      );
    });

    test('fails with the first failure and suppresses the others', () async {
      final first = StateError('first');
      final second = StateError('second');
      final third = StateError('third');

      await expectLater(
        runTest((it) async {
          it.backgroundScope
            ..launch((it) => throw second)
            ..launch((it) => throw third);
          await delay(1.seconds);
          throw first;
        }),
        throwsA(same(first)),
      );
      expect(suppressedExceptionsOf(first), <Object>[second, third]);
    });

    test('fails with the first unhandled failure of several', () async {
      final first = StateError('first');
      final second = StateError('second');

      await expectLater(
        runTest((it) async {
          it.backgroundScope
            ..launch((it) => throw first)
            ..launch((it) => throw second);
          await delay(1.seconds);
        }),
        throwsA(same(first)),
      );
      expect(suppressedExceptionsOf(first), <Object>[second]);
    });

    test('reports a failure of a scope outside the test to its zone', () async {
      final failure = StateError('outside');
      final errors = <Object>[];
      final done = Completer<void>();

      runZonedGuarded(() {
        unawaited(
          runTest((it) async {
            CoroutineScope(SupervisorJob()).launch((it) => throw failure);
            await delay(1.seconds);
          }).then(done.complete, onError: done.completeError),
        );
      }, (error, stackTrace) => errors.add(error));
      await done.future;

      expect(errors, <Object>[failure]);
    });
  });

  group('a test that does not complete', () {
    test('fails once its real time out passed', () async {
      final never = Completer<void>();

      await expectLater(
        runTest(
          (it) => never.future,
          timeout: const Duration(milliseconds: 100),
        ),
        throwsA(
          isA<UncompletedCoroutinesError>().having(
            (it) => it.toString(),
            'text',
            startsWith('UncompletedCoroutinesError: After waiting for '),
          ),
        ),
      );
    });

    test('fails even while it keeps the virtual event loop busy', () async {
      await expectLater(
        runTest((it) async {
          while (true) {
            await yieldNow();
          }
        }, timeout: const Duration(milliseconds: 100)),
        throwsA(isA<UncompletedCoroutinesError>()),
      );
    });
  });
}
