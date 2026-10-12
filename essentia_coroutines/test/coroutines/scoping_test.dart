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

/// Covers the scoping functions on virtual time: `coroutineScope`,
/// `supervisorScope`, `withContext`, `withTimeout` and `withTimeoutOrNull`.
void main() {
  group('coroutineScope', () {
    test(
      'returns once the block and every child are done',
      () => runTest((it) async {
        final log = <String>[];

        final String result = await coroutineScope((it) {
          it.launch((it) async {
            await delay(2.seconds);
            log.add('child');
          });
          return 'block';
        });

        expect(result, 'block');
        expect(log, <String>['child']);
        expect(it.currentTime, 2.seconds);
      }),
    );

    test(
      'throws the first failure after cancelling the siblings',
      () => runTest((it) async {
        final log = <String>[];
        final failure = StateError('broken');

        final Future<void> scope = coroutineScope((it) {
          it
            ..launch((it) async {
              try {
                await delay(10.seconds);
              } finally {
                log.add('sibling cancelled at ${_currentTime(it)}');
              }
            })
            ..launch((it) async {
              await delay(1.seconds);
              throw failure;
            });
        });

        await expectLater(scope, throwsA(same(failure)));
        expect(log, <String>['sibling cancelled at 0:00:01.000000']);
        expect(it.isActive, isTrue);
      }),
    );

    test(
      'throws the failure of the block itself',
      () => runTest((it) async {
        final Future<void> scope = coroutineScope(
          (it) => throw const FormatException(),
        );

        await expectLater(scope, throwsFormatException);
      }),
    );

    test(
      "runs the block at once in the caller's frame",
      () => runTest((it) async {
        final log = <String>[];

        final Future<void> scope = coroutineScope((it) => log.add('block'));
        log.add('called');
        await scope;

        expect(log, <String>['block', 'called']);
      }),
    );

    test(
      'is a child of the current job',
      () => runTest((it) async {
        final test = it;

        await coroutineScope((it) {
          expect(it.coroutineContext.job.parent, same(test));
        });
      }),
    );

    test(
      'is cancelled with the caller',
      () => runTest((it) async {
        final Deferred<void> caller = it.async(
          (it) => coroutineScope((it) => delay(1.hours)),
        );
        it.runCurrent();

        caller.cancel();

        await expectLater(caller, throwsA(isA<CancellationException>()));
      }),
    );
  });

  group('supervisorScope', () {
    test(
      'lets a child fail without cancelling the others',
      () => runTest((it) async {
        final reported = <Object>[];
        final log = <String>[];

        await supervisorScope((it) {
          it
            ..launch(
              (it) => throw StateError('broken'),
              context: CoroutineExceptionHandler(
                (context, error, stackTrace) => reported.add(error),
              ),
            )
            ..launch((it) async {
              await delay(1.seconds);
              log.add('sibling done');
            });
        });

        expect(reported, <Matcher>[isStateError]);
        expect(log, <String>['sibling done']);
      }),
    );

    test(
      'keeps the failure of an async child in its deferred',
      () => runTest((it) async {
        final Deferred<int> failing = await supervisorScope(
          (it) => it.async<int>((it) => throw StateError('broken')),
        );

        expect(failing.getCompletionExceptionOrNull(), isStateError);
      }),
    );

    test(
      'throws the failure of the block and cancels the children',
      () => runTest((it) async {
        final log = <String>[];

        final Future<void> scope = supervisorScope((it) async {
          it.launch((it) async {
            try {
              await awaitCancellation();
            } finally {
              log.add('child cancelled');
            }
          });
          await yieldNow();
          throw const FormatException();
        });

        await expectLater(scope, throwsFormatException);
        expect(log, <String>['child cancelled']);
      }),
    );
  });

  group('withContext', () {
    test(
      "lays the context over the caller's for the block only",
      () => runTest((it) async {
        final String? inside = await withContext(
          const CoroutineName('inner'),
          (it) => currentCoroutineContext().get(CoroutineName.key)?.name,
        );

        expect(inside, 'inner');
        expect(currentCoroutineContext().get(CoroutineName.key), isNull);
      }),
    );

    test(
      'runs the block at once on the same dispatcher',
      () => runTest((it) async {
        final log = <String>[];

        final Future<void> block = withContext(
          const CoroutineName('same'),
          (it) => log.add('block'),
        );
        log.add('called');
        await block;

        expect(log, <String>['block', 'called']);
      }),
    );

    test(
      'dispatches the block on another dispatcher',
      () => runTest((it) async {
        final log = <String>[];

        final Future<CoroutineDispatcher?> block = withContext(
          Dispatchers.main,
          (it) {
            log.add('block');
            return currentCoroutineContext().get(CoroutineDispatcher.key);
          },
        );
        log.add('called');
        final CoroutineDispatcher? dispatcher = await block;

        expect(log, <String>['called', 'block']);
        expect(dispatcher, same(Dispatchers.main));
      }),
    );

    test(
      'waits for the children of the block',
      () => runTest((it) async {
        final log = <String>[];

        await withContext(const CoroutineName('parent'), (it) {
          it.launch((it) async {
            await delay(1.seconds);
            log.add('child');
          });
        });

        expect(log, <String>['child']);
      }),
    );

    test(
      'is not cancelled with the caller under NonCancellable',
      () => runTest((it) async {
        final log = <String>[];
        final Job job = it.launch((it) async {
          try {
            await awaitCancellation();
          } finally {
            await withContext(NonCancellable.instance, (it) async {
              await delay(1.seconds);
              log.add('active ${it.isActive}');
            });
          }
        });
        it.runCurrent();

        await job.cancelAndJoin();

        expect(log, <String>['active true']);
        expect(it.currentTime, 1.seconds);
      }),
    );

    test(
      'refuses to run in a cancelled caller',
      () => runTest((it) async {
        final log = <String>[];
        final Deferred<void> caller = it.async((it) {
          it.cancel();
          return withContext(
            const CoroutineName('late'),
            (it) => log.add('never'),
          );
        });

        await expectLater(caller, throwsA(isA<CancellationException>()));
        expect(log, isEmpty);
      }),
    );

    test(
      'hands a cancelled caller its cancellation, not the result',
      () => runTest((it) async {
        final Deferred<int> caller = it.async((it) {
          final Job callerJob = it.coroutineContext.job;
          return withContext(const CoroutineName('block'), (it) {
            it.coroutineContext.job.invokeOnCompletion(
              (cause) => callerJob.cancel(),
            );
            return 42;
          });
        });

        await expectLater(caller, throwsA(isA<CancellationException>()));
      }),
    );

    test(
      'is cancelled with the caller while the block waits',
      () => runTest((it) async {
        final Deferred<void> caller = it.async(
          (it) => withContext(const CoroutineName('w'), (it) => delay(1.hours)),
        );
        it.runCurrent();

        caller.cancel();

        await expectLater(caller, throwsA(isA<CancellationException>()));
        expect(it.currentTime, Duration.zero);
      }),
    );

    test('runs outside every coroutine', () async {
      final String? name = await withContext(
        const CoroutineName('outside'),
        (it) => currentCoroutineContext().get(CoroutineName.key)?.name,
      );

      expect(name, 'outside');
    });

    test(
      'throws the failure of the block',
      () => runTest((it) async {
        final Future<void> block = withContext(
          const CoroutineName('failing'),
          (it) => throw const FormatException(),
        );

        await expectLater(block, throwsFormatException);
      }),
    );
  });

  group('withTimeout', () {
    test(
      'returns what the block returns in time',
      () => runTest((it) async {
        final int value = await withTimeout(2.seconds, (it) async {
          await delay(1.seconds);
          return 7;
        });

        expect(value, 7);
        expect(it.currentTime, 1.seconds);
        expect(it.testScheduler.pendingTasks, 0);
      }),
    );

    test(
      'cancels the block once the time passed',
      () => runTest((it) async {
        final log = <String>[];

        final Future<void> timed = withTimeout(1.seconds, (it) async {
          try {
            await delay(1.hours);
          } on CancellationException catch (cause) {
            log.add('${cause.runtimeType} at ${_currentTime(it)}');
            rethrow;
          }
        });

        await expectLater(timed, throwsA(isA<TimeoutCancellationException>()));
        expect(log, <String>['TimeoutCancellationException at 0:00:01.000000']);
      }),
    );

    test(
      'times out at once for a time that is not positive',
      () => runTest((it) async {
        final log = <String>[];

        await expectLater(
          withTimeout(Duration.zero, (it) => log.add('never')),
          throwsA(isA<TimeoutCancellationException>()),
        );
        await expectLater(
          withTimeout(-1.seconds, (it) => log.add('never')),
          throwsA(isA<TimeoutCancellationException>()),
        );
        expect(log, isEmpty);
      }),
    );

    test(
      'lets an inner timeout escape an outer one',
      () => runTest((it) async {
        final Future<int?> outer = withTimeoutOrNull(
          10.seconds,
          (it) => withTimeout(5.seconds, (it) => delay(1.hours)).then((_) => 1),
        );

        await expectLater(outer, throwsA(isA<TimeoutCancellationException>()));
        expect(it.currentTime, 5.seconds);
      }),
    );

    test(
      'is cut short by an outer timeout',
      () => runTest((it) async {
        final int? value = await withTimeoutOrNull(5.seconds, (it) async {
          await withTimeout(10.seconds, (it) => delay(1.hours));
          return 1;
        });

        expect(value, isNull);
        expect(it.currentTime, 5.seconds);
      }),
    );

    test('waits on real time outside a test', () async {
      final int value = await withTimeout(1.hours, (it) => 3);

      expect(value, 3);
    });
  });

  group('the coroutine of a scope', () {
    test(
      'renders its kind and state',
      () => runTest((it) async {
        final names = <String>[
          await coroutineScope((it) => '${it.coroutineContext.job}'),
          await supervisorScope((it) => '${it.coroutineContext.job}'),
          await withTimeout(1.seconds, (it) => '${it.coroutineContext.job}'),
          await withContext(
            const CoroutineName('named'),
            (it) => '${it.coroutineContext.job}',
          ),
        ];

        expect(names, <String>[
          'ScopeCoroutine(active)',
          'SupervisorCoroutine(active)',
          'TimeoutCoroutine(active)',
          'ScopeCoroutine[named](active)',
        ]);
      }),
    );
  });

  group('withTimeoutOrNull', () {
    test(
      'returns what the block returns in time',
      () => runTest((it) async {
        final String? value = await withTimeoutOrNull(
          1.seconds,
          (it) => 'done',
        );

        expect(value, 'done');
      }),
    );

    test(
      'returns null once the time passed',
      () => runTest((it) async {
        final String? value = await withTimeoutOrNull(1.seconds, (it) async {
          await delay(1.hours);
          return 'late';
        });

        expect(value, isNull);
        expect(it.currentTime, 1.seconds);
      }),
    );

    test(
      'returns null at once for a time that is not positive',
      () => runTest((it) async {
        final log = <String>[];

        final String? value = await withTimeoutOrNull(Duration.zero, (it) {
          log.add('never');
          return 'x';
        });

        expect(value, isNull);
        expect(log, isEmpty);
      }),
    );

    test(
      'throws the failure of the block',
      () => runTest((it) async {
        await expectLater(
          withTimeoutOrNull(1.seconds, (it) => throw const FormatException()),
          throwsFormatException,
        );
      }),
    );
  });
}

/// The virtual time of the test that [scope] runs in.
///
/// Returns the current time of the scheduler of its context.
Duration _currentTime(CoroutineScope scope) =>
    (scope.coroutineContext.get(Scheduler.key)! as TestScheduler).currentTime;
