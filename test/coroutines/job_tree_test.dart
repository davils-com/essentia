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

import 'foreign_job.dart';

/// Covers the tree of jobs: children, parents waiting for them, failures
/// travelling up, late children, supervisors, `NonCancellable`, parents of
/// another library and who reports an unhandled failure.
void main() {
  group('children', () {
    test('are listed until they complete', () {
      final parent = Job();
      final first = CompletableJob(parent);
      final second = CompletableJob(parent);

      final List<Job> before = parent.children.toList();
      first.complete();

      expect(before, <Job>[first, second]);
      expect(parent.children, <Job>[second]);
      expect(first.parent, isNull);
      expect(second.parent, same(parent));
      expect(
        () => (parent.children as List<Job>).clear(),
        throwsUnsupportedError,
      );
    });

    test('are cancelled with the cause of their parent', () {
      final parent = Job();
      final child = Job(parent);
      final grandchild = Job(child);
      const cause = CancellationException('shutdown');

      parent.cancel(cause);

      expect(child.getCancellationException(), same(cause));
      expect(grandchild.getCancellationException(), same(cause));
    });

    test('do not cancel their parent when cancelled themselves', () {
      final parent = Job();

      Job(parent).cancel();

      expect(parent.isActive, isTrue);
      expect(parent.children, isEmpty);
    });

    test('fail their parent and so their siblings', () {
      final parent = CompletableJob();
      final failing = CompletableJob(parent);
      final sibling = CompletableJob(parent);
      final failure = StateError('broken');
      final causes = <Object?>[];
      parent.invokeOnCompletion(causes.add);

      failing.completeExceptionally(failure);

      expect(sibling.isCancelled, isTrue);
      expect(
        sibling.getCancellationException(),
        isA<JobCancellationException>()
            .having((it) => it.cause, 'cause', same(failure))
            .having((it) => it.job, 'job', same(parent)),
      );
      expect(causes, <Object?>[same(failure)]);
    });

    test('keep their parent completing until they complete', () {
      final parent = CompletableJob();
      final child = CompletableJob(parent);

      parent.complete();
      final bool early = parent.isCompleted;
      child.complete();

      expect(early, isFalse);
      expect(parent.isCompleted, isTrue);
    });

    test(
      'keep a cancelled parent cancelling until they stop',
      () => runTest((it) async {
        final log = <String>[];
        final Job parent = it.launch((it) {
          it.launch((it) async {
            try {
              await awaitCancellation();
            } finally {
              await withContext(
                NonCancellable.instance,
                (it) => delay(1.seconds),
              );
              log.add('child stopped');
            }
          });
        });
        it.runCurrent();

        parent.cancel();
        final cancelling = parent.toString();
        await parent.join();

        expect(cancelling, 'StandaloneCoroutine(cancelling)');
        expect(log, <String>['child stopped']);
        expect(it.currentTime, 1.seconds);
      }),
    );
  });

  group('a late child', () {
    test(
      'of a cancelling parent is cancelled at once',
      () => runTest((it) async {
        final hold = Completer<void>();
        final Job parent = it.launch((it) async {
          try {
            await awaitCancellation();
          } finally {
            await hold.future;
          }
        });
        it.runCurrent();
        parent.cancel(const CancellationException('late'));

        final child = CompletableJob(parent);
        hold.complete();
        await parent.join();

        expect(child.isCancelled, isTrue);
        expect(child.getCancellationException().message, 'late');
      }),
    );

    test('of a cancelled parent is cancelled and not attached', () {
      final failure = StateError('broken');
      final parent = CompletableJob()..completeExceptionally(failure);

      final child = Job(parent);

      expect(child.isCancelled, isTrue);
      expect(child.parent, isNull);
      expect(child.getCancellationException().cause, same(failure));
    });

    test('of a completed parent stays active and is not attached', () {
      final parent = CompletableJob()..complete();

      final child = Job(parent);

      expect(child.isActive, isTrue);
      expect(child.parent, isNull);
      expect(parent.children, isEmpty);
    });

    test(
      'starts a lazily started parent',
      () => runTest((it) async {
        final Job parent = it.launch((it) {}, start: CoroutineStart.lazy);

        final child = CompletableJob(parent);
        final bool started = parent.isActive;
        child.complete();
        await parent.join();

        expect(started, isTrue);
        expect(parent.isCompleted, isTrue);
      }),
    );
  });

  group('a supervisor', () {
    test('lets a child fail alone', () {
      final supervisor = SupervisorJob();
      final failing = CompletableJob(supervisor);
      final sibling = CompletableJob(supervisor);

      failing.completeExceptionally(StateError('broken'));

      expect(failing.isCancelled, isTrue);
      expect(sibling.isActive, isTrue);
      expect(supervisor.isActive, isTrue);
      expect(supervisor.toString(), 'SupervisorJob(active)');
    });

    test(
      'lets each child report its own failure',
      () => runTest((it) async {
        final reported = <Object>[];
        final scope = CoroutineScope(
          SupervisorJob() +
              CoroutineExceptionHandler(
                (context, error, stackTrace) => reported.add(error),
              ),
        );
        final first = StateError('first');
        final second = StateError('second');
        final Job survivor = scope.launch((it) => delay(1.seconds));

        scope
          ..launch((it) => throw first)
          ..launch((it) => throw second);
        it.runCurrent();

        expect(reported, <Object>[first, second]);
        expect(survivor.isActive, isTrue);
        await survivor.join();
      }),
    );

    test('still cancels every child when cancelled', () {
      final supervisor = SupervisorJob();
      final children = <Job>[Job(supervisor), Job(supervisor)];

      supervisor.cancel();

      expect(children.every((child) => child.isCancelled), isTrue);
      expect(supervisor.toString(), 'SupervisorJob(cancelled)');
    });

    test('fails its own parent when it fails itself', () {
      final parent = Job();
      SupervisorJob(parent).completeExceptionally(StateError('broken'));

      expect(parent.isCancelled, isTrue);
    });
  });

  group('NonCancellable', () {
    test('is always active and never completes', () {
      const Job job = NonCancellable.instance;

      job.cancel();

      expect(job.isActive, isTrue);
      expect(job.isCompleted, isFalse);
      expect(job.isCancelled, isFalse);
      expect(job.parent, isNull);
      expect(job.children, isEmpty);
      expect(job.start(), isFalse);
      expect(job.contextKey, same(Job.key));
      expect(job.toString(), 'NonCancellable');
      expect(job.getCancellationException, throwsStateError);
    });

    test('never runs a completion handler', () {
      final log = <String>[];

      NonCancellable.instance
          .invokeOnCompletion((cause) => log.add('ran'))
          .dispose();

      expect(log, isEmpty);
    });

    test(
      'keeps a joiner waiting until the joiner is cancelled',
      () => runTest((it) async {
        final Deferred<void> joining = it.async(
          (it) => NonCancellable.instance.join(),
        );
        it.advanceUntilIdle();
        final bool waiting = joining.isActive;

        joining.cancel();

        expect(waiting, isTrue);
        await expectLater(joining, throwsA(isA<CancellationException>()));
      }),
    );

    test('is the parent of a child that nothing cancels', () {
      final child = Job(NonCancellable.instance);

      expect(child.parent, same(NonCancellable.instance));
      expect(child.isActive, isTrue);
    });
  });

  group('a parent of another library', () {
    test('cancels the child with its cause', () {
      final parent = ForeignJob();
      final child = Job(parent);

      parent.cancel(const CancellationException('foreign stop'));

      expect(child.parent, isNull);
      expect(child.isCancelled, isTrue);
      expect(child.getCancellationException().message, 'foreign stop');
      expect(parent.disposed, 1);
    });

    test('wraps a cause that is not a cancellation', () {
      final parent = ForeignJob();
      final child = Job(parent);

      parent.fire('failed');

      expect(child.getCancellationException().cause, 'failed');
    });

    test('leaves the child alone when it completes normally', () {
      final parent = ForeignJob();
      final child = CompletableJob(parent);

      parent.fire(null);
      final bool active = child.isActive;
      child.complete();

      expect(active, isTrue);
      expect(child.parent, isNull);
      expect(parent.disposed, 1);
    });
  });

  group('an unhandled failure', () {
    test(
      'of a coroutine in a scope of a plain job is reported once and '
      'cancels the scope',
      () => runTest((it) {
        final reported = <Object>[];
        final job = Job();
        final scope = CoroutineScope(
          job +
              CoroutineExceptionHandler(
                (context, error, stackTrace) => reported.add(error),
              ),
        );
        final failure = StateError('broken');

        scope.launch((it) => throw failure);
        it.runCurrent();

        expect(reported, <Object>[failure]);
        expect(job.isCancelled, isTrue);
        expect(job.getCancellationException().cause, same(failure));
      }),
    );

    test(
      'of a nested coroutine is reported once, by the top one',
      () => runTest((it) {
        final reported = <CoroutineContext>[];
        CoroutineScope(
          Job() +
              CoroutineExceptionHandler(
                (context, error, stackTrace) => reported.add(context),
              ),
        ).launch((it) {
          it.launch((it) {
            it.launch((it) => throw StateError('deep'));
          }, context: const CoroutineName('middle'));
        }, context: const CoroutineName('top'));
        it.runCurrent();

        expect(reported, hasLength(1));
        expect(reported.single.get(CoroutineName.key)?.name, 'top');
      }),
    );

    test(
      'of a job under a coroutine is taken over by the coroutine',
      () => runTest((it) async {
        final reported = <Object>[];
        final scope = CoroutineScope(
          SupervisorJob() +
              CoroutineExceptionHandler(
                (context, error, stackTrace) => reported.add(error),
              ),
        );
        final failure = StateError('broken');

        final Job top = scope.launch((it) {
          final job = Job(it.coroutineContext.job);
          CoroutineScope(job).launch((it) => throw failure);
        });
        await top.join();

        expect(reported, <Object>[failure]);
      }),
    );

    test('of a plain job is reported nowhere', () {
      final errors = <Object>[];

      runZonedGuarded(
        () => CompletableJob().completeExceptionally(StateError('quiet')),
        (error, stackTrace) => errors.add(error),
      );

      expect(errors, isEmpty);
    });
  });
}
