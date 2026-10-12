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

/// Covers the coroutine builders: `launch` and `async` with every
/// `CoroutineStart`, a `Deferred` as a `Future`, `CompletableDeferred`,
/// `awaitAll`, `asDeferred`, and the scopes they start in.
void main() {
  group('launch', () {
    test(
      'dispatches the body by default',
      () => runTest((it) {
        final log = <String>[];

        final Job job = it.launch((it) => log.add('body'));
        log.add('launched');
        final state = job.toString();
        it.runCurrent();

        expect(log, <String>['launched', 'body']);
        expect(state, 'StandaloneCoroutine(active)');
        expect(job.isCompleted, isTrue);
      }),
    );

    test(
      'never runs the body when cancelled before it was dispatched',
      () => runTest((it) {
        final log = <String>[];

        final Job job = it.launch((it) => log.add('body'))..cancel();
        final state = job.toString();
        it.runCurrent();

        expect(state, 'StandaloneCoroutine(cancelling)');
        expect(log, isEmpty);
        expect(job.toString(), 'StandaloneCoroutine(cancelled)');
      }),
    );

    test(
      'runs an atomic body even when cancelled before it ran',
      () => runTest((it) {
        final log = <String>[];

        final Job job = it.launch((it) {
          log.add('body active ${it.isActive}');
          it.ensureActive();
          log.add('never');
        }, start: CoroutineStart.atomic)..cancel();
        it.runCurrent();

        expect(log, <String>['body active false']);
        expect(job.isCancelled, isTrue);
      }),
    );

    test(
      'runs an undispatched body at once until it first waits',
      () => runTest((it) async {
        final log = <String>[];

        it.launch((it) async {
          log.add('before');
          await delay(1.seconds);
          log.add('after');
        }, start: CoroutineStart.undispatched);
        log.add('launched');
        await delay(2.seconds);

        expect(log, <String>['before', 'launched', 'after']);
      }),
    );

    test(
      'starts a lazy body only when started',
      () => runTest((it) {
        final log = <String>[];

        final Job job = it.launch(
          (it) => log.add('body'),
          start: CoroutineStart.lazy,
        );
        it.runCurrent();
        final state = job.toString();
        final bool started = job.start();
        final bool again = job.start();
        it.runCurrent();

        expect(state, 'StandaloneCoroutine(new)');
        expect(started, isTrue);
        expect(again, isFalse);
        expect(log, <String>['body']);
      }),
    );

    test(
      'never runs a lazy body that was cancelled before it started',
      () => runTest((it) {
        final log = <String>[];

        final Job job = it.launch(
          (it) => log.add('body'),
          start: CoroutineStart.lazy,
        )..cancel();
        final bool started = job.start();
        it.runCurrent();

        expect(started, isFalse);
        expect(log, isEmpty);
        expect(job.toString(), 'StandaloneCoroutine(cancelled)');
      }),
    );

    test(
      'lays its context over the scope and names the coroutine',
      () => runTest((it) async {
        final Job job = it.launch(
          (it) => delay(1.seconds),
          context: const CoroutineName('worker'),
        );

        expect(job.toString(), 'StandaloneCoroutine[worker](active)');
        expect(job.parent, same(it));
        expect(it.coroutineContext.job.children, <Job>[job]);
        await job.join();
      }),
    );

    test(
      'starts a child of the job of the scope',
      () => runTest((it) async {
        final parent = Job();
        final Job job = CoroutineScope(parent).launch((it) {});

        expect(job.parent, same(parent));
        await job.join();
      }),
    );
  });

  group('async', () {
    test(
      'keeps the result of its body',
      () => runTest((it) async {
        final Deferred<int> answer = it.async((it) async {
          await delay(1.seconds);
          return 42;
        });

        expect(await answer, 42);
        expect(answer.getCompleted(), 42);
        expect(answer.getCompletionExceptionOrNull(), isNull);
        expect(answer.toString(), 'DeferredCoroutine(completed)');
      }),
    );

    test(
      'starts a lazy body when awaited',
      () => runTest((it) async {
        final log = <String>[];
        final Deferred<int> answer = it.async((it) {
          log.add('body');
          return 42;
        }, start: CoroutineStart.lazy);
        it.runCurrent();
        final before = List<String>.of(log);

        final int value = await answer;

        expect(before, isEmpty);
        expect(value, 42);
      }),
    );

    test(
      'runs an undispatched body at once',
      () => runTest((it) async {
        final log = <String>[];

        final Deferred<int> answer = it.async((it) {
          log.add('body');
          return 1;
        }, start: CoroutineStart.undispatched);
        log.add('started');

        expect(log, <String>['body', 'started']);
        expect(await answer, 1);
      }),
    );

    test(
      'refuses the result while it is not complete',
      () => runTest((it) async {
        final Deferred<int> answer = it.async((it) => 1);

        expect(answer.getCompleted, throwsStateError);
        expect(answer.getCompletionExceptionOrNull, throwsStateError);
        await answer;
      }),
    );

    test(
      'keeps its failure for whoever awaits it',
      () => runTest((it) async {
        final failure = StateError('broken');
        final Deferred<int> answer = await supervisorScope(
          (it) => it.async<int>((it) => throw failure),
        );

        expect(answer.getCompletionExceptionOrNull(), same(failure));
        expect(answer.getCompleted, throwsA(same(failure)));
        await expectLater(answer, throwsA(same(failure)));
      }),
    );

    test(
      'keeps the cancellation of a cancelled deferred',
      () => runTest((it) async {
        final Deferred<int> answer = it.async((it) async {
          await awaitCancellation();
        });
        it.runCurrent();

        answer.cancel(const CancellationException('stop'));
        it.runCurrent();

        expect(
          answer.getCompletionExceptionOrNull(),
          isA<CancellationException>(),
        );
        await expectLater(answer, throwsA(isA<CancellationException>()));
      }),
    );

    test(
      'fails the scope it was started in',
      () => runTest((it) async {
        final failure = StateError('broken');
        final Future<void> scope = coroutineScope((it) {
          unawaited(it.async<int>((it) => throw failure));
        });

        await expectLater(scope, throwsA(same(failure)));
      }),
    );
  });

  group('a deferred as a future', () {
    test(
      'answers then, catchError and whenComplete',
      () => runTest((it) async {
        final Deferred<int> answer = it.async((it) => 21);
        final log = <String>[];

        final int doubled = await answer.then((value) => value * 2);
        final int caught = await answer.catchError((Object error) => 0);
        await answer.whenComplete(() => log.add('complete'));

        expect(doubled, 42);
        expect(caught, 21);
        expect(log, <String>['complete']);
      }),
    );

    test(
      'hands its failure to catchError and onError',
      () => runTest((it) async {
        await supervisorScope((it) async {
          final Deferred<int> answer = it.async((it) => throw StateError('x'));

          final int caught = await answer.catchError(
            (Object error) => -1,
            test: (error) => error is StateError,
          );
          final int handled = await answer.then(
            (value) => value,
            onError: (Object error) => -2,
          );

          expect(caught, -1);
          expect(handled, -2);
        });
      }),
    );

    test(
      'is a stream of its one value',
      () => runTest((it) async {
        final Deferred<int> answer = it.async((it) => 7);

        expect(await answer.asStream().toList(), <int>[7]);
      }),
    );

    test(
      'times out on virtual time',
      () => runTest((it) async {
        final Deferred<int> slow = it.async((it) async {
          await delay(1.hours);
          return 1;
        });

        final int value = await slow.timeout(1.seconds, onTimeout: () => -1);

        expect(value, -1);
        expect(it.currentTime, 1.seconds);
        slow.cancel();
      }),
    );

    test(
      'is waited for together with plain futures',
      () => runTest((it) async {
        final Deferred<int> first = it.async((it) async {
          await delay(2.seconds);
          return 1;
        });
        final Deferred<int> second = it.async((it) async {
          await delay(1.seconds);
          return 2;
        });

        final List<int> values = await Future.wait(<Future<int>>[
          first,
          second,
          Future<int>.value(3),
        ]);

        expect(values, <int>[1, 2, 3]);
        expect(it.currentTime, 2.seconds);
      }),
    );

    test(
      'is awaited cancellably',
      () => runTest((it) async {
        final never = CompletableDeferred<int>();
        final Deferred<int> waiting = it.async((it) => never);
        it.runCurrent();

        waiting.cancel();

        await expectLater(waiting, throwsA(isA<CancellationException>()));
        expect(never.isActive, isTrue);
      }),
    );

    test(
      'answers at once once it is complete',
      () => runTest((it) async {
        final done = CompletableDeferred<int>()..complete(5);
        final failed = CompletableDeferred<int>()
          ..completeExceptionally(StateError('broken'));

        expect(await done, 5);
        await expectLater(failed, throwsStateError);
      }),
    );
  });

  group('CompletableDeferred', () {
    test(
      'completes once with a value',
      () => runTest((it) async {
        final deferred = CompletableDeferred<String>();
        final active = deferred.toString();

        final bool first = deferred.complete('a');
        final bool second = deferred.complete('b');
        final bool failed = deferred.completeExceptionally(StateError('x'));

        expect(active, 'CompletableDeferred(active)');
        expect(first, isTrue);
        expect(second, isFalse);
        expect(failed, isFalse);
        expect(await deferred, 'a');
        expect(deferred.toString(), 'CompletableDeferred(completed)');
      }),
    );

    test(
      'fails once with a failure',
      () => runTest((it) {
        final deferred = CompletableDeferred<String>();
        final failure = StateError('broken');

        final bool first = deferred.completeExceptionally(failure);
        final bool second = deferred.complete('late');

        expect(first, isTrue);
        expect(second, isFalse);
        expect(deferred.getCompletionExceptionOrNull(), same(failure));
        expect(deferred.toString(), 'CompletableDeferred(cancelled)');
      }),
    );

    test('refuses to complete once cancelled', () {
      final deferred = CompletableDeferred<int>()..cancel();

      expect(deferred.complete(1), isFalse);
      expect(deferred.completeExceptionally(StateError('x')), isFalse);
      expect(deferred.isCancelled, isTrue);
    });

    test('is a child of the job it is given', () {
      final parent = Job();
      final deferred = CompletableDeferred<int>(parent);

      parent.cancel();

      expect(deferred.isCancelled, isTrue);
    });

    test(
      'resumes a waiter once completed',
      () => runTest((it) async {
        final deferred = CompletableDeferred<int>();
        it.launch((it) async {
          await delay(1.seconds);
          deferred.complete(3);
        });

        expect(await deferred, 3);
        expect(it.currentTime, 1.seconds);
      }),
    );
  });

  group('awaitAll', () {
    test(
      'answers the values in order',
      () => runTest((it) async {
        final all = <Deferred<int>>[
          for (var index = 3; index > 0; index--)
            it.async((it) async {
              await delay(Duration(seconds: index));
              return index;
            }),
        ];

        expect(await all.awaitAll(), <int>[3, 2, 1]);
        expect(await <Deferred<int>>[].awaitAll(), isEmpty);
      }),
    );

    test(
      'fails at once with the first failure',
      () => runTest((it) async {
        await supervisorScope((it) async {
          final failure = StateError('broken');
          final Deferred<int> slow = it.async((it) async {
            await delay(1.hours);
            return 1;
          });
          final Deferred<int> failing = it.async((it) async {
            await delay(1.seconds);
            throw failure;
          });

          await expectLater(
            <Deferred<int>>[slow, failing].awaitAll(),
            throwsA(same(failure)),
          );
          expect(_currentTimeOf(it), 1.seconds);
          expect(slow.isActive, isTrue);
          slow.cancel();
        });
      }),
    );

    test(
      'starts lazily started values',
      () => runTest((it) async {
        final Deferred<int> lazy = it.async(
          (it) => 1,
          start: CoroutineStart.lazy,
        );

        expect(await <Deferred<int>>[lazy].awaitAll(), <int>[1]);
      }),
    );

    test(
      'is cancellable',
      () => runTest((it) async {
        final never = CompletableDeferred<int>();
        final Deferred<List<int>> waiting = it.async(
          (it) => <Deferred<int>>[never].awaitAll(),
        );
        it.runCurrent();

        waiting.cancel();
        never.complete(1);

        await expectLater(waiting, throwsA(isA<CancellationException>()));
      }),
    );

    test(
      'fails with the failure of a converted future',
      () => runTest((it) async {
        final Deferred<int> deferred = Future<int>.error(StateError('x'))
            .asDeferred();

        await expectLater(
          <Deferred<int>>[deferred].awaitAll(),
          throwsStateError,
        );
      }),
    );
  });

  group('asDeferred', () {
    test(
      'completes with the value of the future',
      () => runTest((it) async {
        final Deferred<int> deferred = Future<int>.value(4).asDeferred();

        expect(await deferred, 4);
        expect(deferred.parent, isNull);
      }),
    );

    test(
      'fails with the error of the future',
      () => runTest((it) async {
        final Deferred<int> deferred = Future<int>.error(
          const FormatException(),
        ).asDeferred();

        await expectLater(deferred, throwsFormatException);
      }),
    );

    test(
      'makes waiting for a plain future cancellable',
      () => runTest((it) async {
        final pending = Completer<int>();
        final Deferred<int> waiting = it.async(
          (it) => pending.future.asDeferred(),
        );
        it.runCurrent();

        waiting.cancel();

        await expectLater(waiting, throwsA(isA<CancellationException>()));
        pending.complete(1);
      }),
    );
  });

  group('a scope', () {
    test('adds a job to a context without one', () {
      final scope = CoroutineScope(const CoroutineName('a'));

      expect(scope.coroutineContext.get(Job.key), isA<CompletableJob>());
      expect(scope.isActive, isTrue);
      expect(
        scope.toString(),
        'CoroutineScope(coroutineContext=[CoroutineName(a), Job(active)])',
      );
    });

    test('keeps the job of its context', () {
      final job = Job();

      expect(CoroutineScope(job).coroutineContext, same(job));
    });

    test('cancels its job and every coroutine in it', () {
      final job = Job();
      final scope = CoroutineScope(job);
      final Job child = scope.launch((it) {});

      scope.cancel();

      expect(job.isCancelled, isTrue);
      expect(child.isCancelled, isTrue);
      expect(scope.isActive, isFalse);
      expect(scope.ensureActive, throwsA(isA<CancellationException>()));
    });

    test('lays a context over its own with plus', () {
      final job = Job();
      final CoroutineScope scope =
          CoroutineScope(job) + const CoroutineName('b');

      expect(scope.coroutineContext.get(Job.key), same(job));
      expect(
        scope.coroutineContext.get(CoroutineName.key),
        const CoroutineName('b'),
      );
    });

    test('without a job cannot be cancelled', () {
      expect(GlobalScope.instance.cancel, throwsStateError);
      expect(GlobalScope.instance.isActive, isTrue);
      expect(GlobalScope.instance.ensureActive, returnsNormally);
    });

    test('of the program is global and empty', () {
      expect(GlobalScope.instance.coroutineContext, CoroutineContext.empty);
      expect(GlobalScope.instance.toString(), 'GlobalScope');
    });

    test(
      'of the program starts coroutines without a parent',
      () => runTest((it) async {
        final Job job = GlobalScope.instance.launch((it) => delay(1.seconds));

        expect(job.parent, isNull);
        expect(it.coroutineContext.job.children, isEmpty);
        await job.join();
      }),
    );

    test('of the main work is a supervisor on the event loop', () {
      final CoroutineScope scope = mainScope();

      expect(scope.coroutineContext.get(Job.key), isA<SupervisorJob>());
      expect(
        scope.coroutineContext.get(CoroutineDispatcher.key),
        same(Dispatchers.main),
      );
    });
  });
}

/// The virtual time of the test that [scope] runs in.
///
/// Returns the current time of the scheduler of its context.
Duration _currentTimeOf(CoroutineScope scope) =>
    (scope.coroutineContext.get(Scheduler.key)! as TestScheduler).currentTime;
