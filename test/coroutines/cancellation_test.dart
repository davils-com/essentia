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

/// Covers cooperative cancellation: the waits that are cancellation
/// checkpoints, `ensureActive`, `awaitCancellation`,
/// `suspendCancellableCoroutine` with prompt cancellation, `finally`
/// blocks and `cancelAndJoin`.
void main() {
  group('a checkpoint', () {
    test(
      'delay ends with the cancellation and calls its timer off',
      () => runTest((it) async {
        final Deferred<void> waiting = it.async((it) => delay(1.hours));
        it.runCurrent();
        final int pending = it.testScheduler.pendingTasks;

        waiting.cancel(const CancellationException('stop'));

        await expectLater(
          waiting,
          throwsA(
            isA<CancellationException>().having(
              (it) => it.message,
              'message',
              'stop',
            ),
          ),
        );
        expect(pending, 1);
        expect(it.testScheduler.pendingTasks, 0);
      }),
    );

    test(
      'delay of nothing still checks for cancellation',
      () => runTest((it) async {
        final Deferred<void> waiting = it.async((it) {
          it.cancel();
          return delay(Duration.zero);
        });

        await expectLater(waiting, throwsA(isA<CancellationException>()));
      }),
    );

    test(
      'yieldNow lets other work run first',
      () => runTest((it) async {
        final log = <String>[];
        it.launch((it) => log.add('other'));

        await yieldNow();
        log.add('after yield');

        expect(log, <String>['other', 'after yield']);
      }),
    );

    test(
      'yieldNow stops a loop that is cancelled',
      () => runTest((it) async {
        var rounds = 0;
        final Job loop = it.launch((it) async {
          while (true) {
            rounds++;
            await yieldNow();
          }
        });
        await yieldNow();

        await loop.cancelAndJoin();

        expect(loop.isCancelled, isTrue);
        expect(rounds, greaterThan(0));
      }),
    );

    test(
      'yieldNow throws at once inside a cancelled job',
      () => runTest((it) async {
        final Deferred<void> waiting = it.async((it) {
          it.cancel();
          return yieldNow();
        });

        await expectLater(waiting, throwsA(isA<CancellationException>()));
      }),
    );

    test('yieldNow passes outside every coroutine', () async {
      await yieldNow();
    });
  });

  group('ensureActive', () {
    test('passes outside every coroutine', () {
      expect(ensureActive, returnsNormally);
    });

    test(
      'throws the cancellation inside a cancelled coroutine',
      () => runTest((it) async {
        final log = <String>[];
        final Job job = it.launch((it) {
          it.cancel(const CancellationException('stop'));
          try {
            ensureActive();
          } on CancellationException catch (cause) {
            log.add(cause.message!);
          }
        }, start: CoroutineStart.undispatched);

        await job.join();

        expect(log, <String>['stop']);
      }),
    );
  });

  group('isCurrentCancellation', () {
    test(
      'is true for a cancellation inside a cancelled coroutine',
      () => runTest((it) {
        final answers = <bool>[];
        it.launch((it) {
          it.cancel();
          answers
            ..add(isCurrentCancellation(const CancellationException()))
            ..add(isCurrentCancellation(StateError('other')));
        }, start: CoroutineStart.undispatched);

        expect(answers, <bool>[true, false]);
      }),
    );

    test(
      'is false for a cancellation while the job is active',
      () => runTest((it) {
        expect(isCurrentCancellation(const CancellationException()), isFalse);
      }),
    );

    test('is false outside every job', () {
      expect(isCurrentCancellation(const CancellationException()), isFalse);
      expect(isCurrentCancellation(StateError('other')), isFalse);
    });
  });

  group('awaitCancellation', () {
    test(
      'waits until the job is cancelled',
      () => runTest((it) async {
        final Deferred<Never> waiting = it.async((it) => awaitCancellation());
        it.advanceUntilIdle();
        final bool active = waiting.isActive;

        waiting.cancel();

        expect(active, isTrue);
        await expectLater(waiting, throwsA(isA<CancellationException>()));
      }),
    );
  });

  group('suspendCancellableCoroutine', () {
    test(
      'answers the value it is resumed with',
      () => runTest((it) async {
        final int value = await suspendCancellableCoroutine<int>((it) {
          Timer(1.seconds, () => it.resume(5));
        });

        expect(value, 5);
        expect(it.currentTime, 1.seconds);
      }),
    );

    test(
      'throws the error it is resumed with',
      () => runTest((it) async {
        await expectLater(
          suspendCancellableCoroutine<int>(
            (it) => it.resumeWithException(const FormatException()),
          ),
          throwsFormatException,
        );
      }),
    );

    test(
      'throws what the block throws',
      () => runTest((it) async {
        await expectLater(
          suspendCancellableCoroutine<int>(
            (it) => throw const FormatException(),
          ),
          throwsFormatException,
        );
      }),
    );

    test(
      'throws what the block throws after resuming',
      () => runTest((it) async {
        await expectLater(
          suspendCancellableCoroutine<int>((it) {
            it.resume(1);
            throw const FormatException();
          }),
          throwsFormatException,
        );
      }),
    );

    test('works outside every coroutine', () async {
      final int value = await suspendCancellableCoroutine<int>(
        (it) => it.resume(9),
      );

      expect(value, 9);
    });

    test(
      'tracks the state of its continuation',
      () => runTest((it) async {
        final states = <String>[];
        final int value = await suspendCancellableCoroutine<int>((it) {
          states.add('$it ${it.isActive} ${it.isCompleted} ${it.isCancelled}');
          it.resume(1);
          states.add('$it ${it.isActive} ${it.isCompleted} ${it.isCancelled}');
        });

        expect(value, 1);
        expect(states, <String>[
          'CancellableContinuation(active) true false false',
          'CancellableContinuation(resumed) false true false',
        ]);
      }),
    );

    test(
      'refuses a second resume',
      () => runTest((it) async {
        final int value = await suspendCancellableCoroutine<int>((it) {
          it.resume(1);
          expect(() => it.resume(2), throwsStateError);
          expect(
            () => it.resumeWithException(const FormatException()),
            throwsStateError,
          );
        });

        expect(value, 1);
      }),
    );

    test(
      'is cancelled with its job and runs the cancellation handler',
      () => runTest((it) async {
        final log = <String>[];
        final Deferred<int> waiting = it.async(
          (it) => suspendCancellableCoroutine<int>((it) {
            it.invokeOnCancellation((cause) => log.add('$cause'));
          }),
        );
        it.runCurrent();

        waiting.cancel(const CancellationException('stop'));

        await expectLater(waiting, throwsA(isA<CancellationException>()));
        expect(log, <String>['CancellationException: stop']);
      }),
    );

    test(
      'is cancelled by itself with its cause',
      () => runTest((it) async {
        final states = <String>[];
        final Future<int> waiting = suspendCancellableCoroutine<int>((it) {
          final bool first = it.cancel(const FormatException('own'));
          final bool second = it.cancel();
          states.add('$it $first $second ${it.isCancelled} ${it.isActive}');
          it.resumeWithException(StateError('ignored'));
        });

        await expectLater(waiting, throwsFormatException);
        expect(states, <String>[
          'CancellableContinuation(cancelled) true false true false',
        ]);
      }),
    );

    test(
      'is cancelled with a cancellation when no cause is given',
      () => runTest((it) async {
        await expectLater(
          suspendCancellableCoroutine<int>((it) => it.cancel()),
          throwsA(
            isA<CancellationException>().having(
              (it) => it.message,
              'message',
              'Continuation was cancelled',
            ),
          ),
        );
      }),
    );

    test(
      'runs a cancellation handler at once once cancelled',
      () => runTest((it) async {
        final causes = <Object?>[];
        final Future<int> waiting = suspendCancellableCoroutine<int>((it) {
          it
            ..cancel(const FormatException('own'))
            ..invokeOnCancellation(causes.add);
        });

        await expectLater(waiting, throwsFormatException);
        expect(causes, <Matcher>[isFormatException]);
      }),
    );

    test(
      'never runs a cancellation handler once resumed',
      () => runTest((it) async {
        final causes = <Object?>[];
        final int value = await suspendCancellableCoroutine<int>((it) {
          it
            ..resume(1)
            ..invokeOnCancellation(causes.add);
        });

        expect(value, 1);
        expect(causes, isEmpty);
      }),
    );

    test(
      'refuses a second cancellation handler',
      () => runTest((it) async {
        final int value = await suspendCancellableCoroutine<int>((it) {
          it.invokeOnCancellation((cause) {});
          expect(() => it.invokeOnCancellation((cause) {}), throwsStateError);
          it.resume(1);
        });

        expect(value, 1);
      }),
    );

    test('reports a cancellation handler that throws', () {
      final errors = <Object>[];

      runZonedGuarded(() {
        suspendCancellableCoroutine<int>((it) {
          it
            ..invokeOnCancellation((cause) => throw const FormatException())
            ..cancel();
        }).ignore();
      }, (error, stackTrace) => errors.add(error));

      expect(errors, <Matcher>[isFormatException]);
    });

    test(
      'hands a value to onCancellation once it is cancelled',
      () => runTest((it) async {
        final dropped = <String>[];
        final Future<int> waiting = suspendCancellableCoroutine<int>((it) {
          it
            ..cancel()
            ..resume(
              7,
              onCancellation: (cause, value) => dropped.add('$value $cause'),
            )
            ..resume(8);
        });

        await expectLater(waiting, throwsA(isA<CancellationException>()));
        expect(dropped, <String>[
          '7 CancellationException: Continuation was cancelled',
        ]);
      }),
    );

    test(
      'delivers no value to a job cancelled after the resume',
      () => runTest((it) async {
        final dropped = <String>[];
        final log = <String>[];
        final Job job = it.launch((it) async {
          try {
            await suspendCancellableCoroutine<int>((continuation) {
              continuation.resume(
                7,
                onCancellation: (cause, value) => dropped.add('$value'),
              );
              it.cancel(const CancellationException('prompt'));
            });
            log.add('never');
          } on CancellationException catch (cause) {
            log.add(cause.message!);
          }
        });

        await job.join();

        expect(dropped, <String>['7']);
        expect(log, <String>['prompt']);
      }),
    );

    test(
      'delivers a value without onCancellation to nobody',
      () => runTest((it) async {
        final log = <String>[];
        final Job job = it.launch((it) async {
          try {
            await suspendCancellableCoroutine<int>((continuation) {
              continuation.resume(7);
              it.cancel();
            });
          } on CancellationException {
            log.add('cancelled');
          }
        });

        await job.join();

        expect(log, <String>['cancelled']);
      }),
    );

    test(
      'follows a job that is cancelled by a failure',
      () => runTest((it) async {
        await supervisorScope((it) async {
          final failure = StateError('broken');
          final parent = CompletableJob();
          final Deferred<int> waiting = it.async(
            (it) => suspendCancellableCoroutine<int>((it) {}),
            context: parent,
          );
          await yieldNow();

          parent.completeExceptionally(failure);

          await expectLater(
            waiting,
            throwsA(
              isA<JobCancellationException>().having(
                (it) => it.cause,
                'cause',
                same(failure),
              ),
            ),
          );
        });
      }),
    );
  });

  group('cancelling a coroutine', () {
    test(
      'runs its finally blocks',
      () => runTest((it) {
        final log = <String>[];
        final Job job = it.launch((it) async {
          try {
            try {
              await delay(1.hours);
            } finally {
              log.add('inner');
            }
          } finally {
            log.add('outer');
          }
        });
        it.runCurrent();

        job.cancel();
        it.runCurrent();

        expect(log, <String>['inner', 'outer']);
        expect(job.isCompleted, isTrue);
      }),
    );

    test(
      'with cancelAndJoin waits until it really ended',
      () => runTest((it) async {
        final log = <String>[];
        final Job job = it.launch((it) async {
          try {
            await awaitCancellation();
          } finally {
            await withContext(NonCancellable.instance, (it) async {
              await delay(5.seconds);
              log.add('cleaned up');
            });
          }
        });
        it.runCurrent();

        await job.cancelAndJoin();
        log.add('joined at ${it.currentTime}');

        expect(log, <String>['cleaned up', 'joined at 0:00:05.000000']);
      }),
    );

    test(
      'leaves work that never waits running to its end',
      () => runTest((it) async {
        var steps = 0;
        final Job job = it.launch((it) {
          for (var step = 0; step < 5; step++) {
            steps++;
          }
        }, start: CoroutineStart.undispatched);

        await job.cancelAndJoin();

        expect(steps, 5);
      }),
    );
  });
}
