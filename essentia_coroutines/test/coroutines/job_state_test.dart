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
import 'package:test/test.dart';

import 'job_probe.dart';
import 'job_table_event.dart';
import 'job_table_state.dart';

/// The failure the events of the table fail with.
final _boom = StateError('boom');

/// Starts a probe in [scope] and moves it to [state], running what is due
/// on [test].
///
/// Returns the probe.
JobProbe _probeIn(TestScope test, CoroutineScope scope, JobTableState state) {
  final gate = CompletableDeferred<bool>();
  final release = Completer<void>();
  if (state != JobTableState.cancelling) {
    release.complete();
  }
  final Job job = scope.launch(
    (it) async {
      try {
        await gate;
      } finally {
        await release.future;
      }
    },
    start: state == JobTableState.fresh
        ? CoroutineStart.lazy
        : CoroutineStart.defaultStart,
  );
  final probe = JobProbe(job, gate, release, _boom);
  test.runCurrent();
  switch (state) {
    case JobTableState.fresh:
    case JobTableState.active:
      break;
    case JobTableState.completing:
      probe.holder = CompletableJob(job);
      gate.complete(true);
    case JobTableState.cancelling:
    case JobTableState.cancelled:
      job.cancel();
    case JobTableState.completed:
      gate.complete(true);
  }
  test.runCurrent();
  return probe;
}

/// What every (state, event) pair leads to, and whether [_boom] is
/// reported.
const _table = <JobTableState, Map<JobTableEvent, (JobTableState, bool)>>{
  JobTableState.fresh: {
    JobTableEvent.start: (JobTableState.active, false),
    JobTableEvent.cancel: (JobTableState.cancelled, false),
    JobTableEvent.complete: (JobTableState.fresh, false),
    JobTableEvent.completeExceptionally: (JobTableState.fresh, false),
    JobTableEvent.childComplete: (JobTableState.active, false),
    JobTableEvent.childFail: (JobTableState.cancelled, true),
  },
  JobTableState.active: {
    JobTableEvent.start: (JobTableState.active, false),
    JobTableEvent.cancel: (JobTableState.cancelled, false),
    JobTableEvent.complete: (JobTableState.completed, false),
    JobTableEvent.completeExceptionally: (JobTableState.cancelled, true),
    JobTableEvent.childComplete: (JobTableState.active, false),
    JobTableEvent.childFail: (JobTableState.cancelled, true),
  },
  JobTableState.completing: {
    JobTableEvent.start: (JobTableState.completing, false),
    JobTableEvent.cancel: (JobTableState.cancelled, false),
    JobTableEvent.complete: (JobTableState.completing, false),
    JobTableEvent.completeExceptionally: (JobTableState.completing, false),
    JobTableEvent.childComplete: (JobTableState.completed, false),
    JobTableEvent.childFail: (JobTableState.cancelled, true),
  },
  JobTableState.cancelling: {
    JobTableEvent.start: (JobTableState.cancelling, false),
    JobTableEvent.cancel: (JobTableState.cancelling, false),
    JobTableEvent.complete: (JobTableState.cancelled, false),
    JobTableEvent.completeExceptionally: (JobTableState.cancelled, true),
    JobTableEvent.childComplete: (JobTableState.cancelling, false),
    JobTableEvent.childFail: (JobTableState.cancelling, false),
  },
  JobTableState.cancelled: {
    JobTableEvent.start: (JobTableState.cancelled, false),
    JobTableEvent.cancel: (JobTableState.cancelled, false),
    JobTableEvent.complete: (JobTableState.cancelled, false),
    JobTableEvent.completeExceptionally: (JobTableState.cancelled, false),
    JobTableEvent.childComplete: (JobTableState.cancelled, false),
    JobTableEvent.childFail: (JobTableState.cancelled, false),
  },
  JobTableState.completed: {
    JobTableEvent.start: (JobTableState.completed, false),
    JobTableEvent.cancel: (JobTableState.completed, false),
    JobTableEvent.complete: (JobTableState.completed, false),
    JobTableEvent.completeExceptionally: (JobTableState.completed, false),
    JobTableEvent.childComplete: (JobTableState.completed, false),
    JobTableEvent.childFail: (JobTableState.completed, false),
  },
};

/// Checks that [job] is in [state].
void _expectState(Job job, JobTableState state) {
  expect(job.toString(), 'StandaloneCoroutine(${state.label})');
  expect(job.isActive, state.isActive, reason: 'isActive of $job');
  expect(job.isCompleted, state.isCompleted, reason: 'isCompleted of $job');
  expect(job.isCancelled, state.isCancelled, reason: 'isCancelled of $job');
}

/// Covers the life cycle of a job: every state under every event, with
/// the flags, the rendering and the cancellation exception of each state.
void main() {
  group('a coroutine', () {
    for (final JobTableState state in JobTableState.values) {
      test(
        'starts out ${state.label} with the flags of the state',
        () => runTest((it) {
          final scope = CoroutineScope(SupervisorJob());

          final JobProbe probe = _probeIn(it, scope, state);

          _expectState(probe.job, state);
          probe.apply(JobTableEvent.complete);
          scope.cancel();
          it.runCurrent();
        }),
      );

      for (final MapEntry<JobTableEvent, (JobTableState, bool)> entry
          in _table[state]!.entries) {
        final JobTableEvent event = entry.key;
        final (JobTableState after, bool reports) = entry.value;
        test(
          'moves from ${state.label} on ${event.name} to ${after.label}'
          '${reports ? ', reporting the failure' : ''}',
          () => runTest((it) {
            final reported = <Object>[];
            final scope = CoroutineScope(
              SupervisorJob() +
                  CoroutineExceptionHandler(
                    (context, error, stackTrace) => reported.add(error),
                  ),
            );
            final JobProbe probe = _probeIn(it, scope, state)..apply(event);
            it.runCurrent();

            _expectState(probe.job, after);
            expect(reported, reports ? <Object>[_boom] : isEmpty);
            probe.apply(JobTableEvent.complete);
            scope.cancel();
            it.runCurrent();
          }),
        );
      }
    }
  });

  group('the cancellation exception', () {
    for (final state in <JobTableState>[
      JobTableState.fresh,
      JobTableState.active,
      JobTableState.completing,
    ]) {
      test(
        'is refused while the job is ${state.label}',
        () => runTest((it) {
          final scope = CoroutineScope(SupervisorJob());
          final JobProbe probe = _probeIn(it, scope, state);

          expect(probe.job.getCancellationException, throwsStateError);
          probe.apply(JobTableEvent.complete);
          scope.cancel();
          it.runCurrent();
        }),
      );
    }

    test(
      'is the cause while the job is cancelling',
      () => runTest((it) {
        final scope = CoroutineScope(SupervisorJob());
        final JobProbe probe = _probeIn(it, scope, JobTableState.cancelling);

        expect(
          probe.job.getCancellationException(),
          isA<JobCancellationException>().having(
            (it) => it.job,
            'job',
            same(probe.job),
          ),
        );
        probe.apply(JobTableEvent.complete);
        it.runCurrent();
      }),
    );

    test('is the cause given to cancel once the job is cancelled', () {
      const cause = CancellationException('user left');

      final job = Job()..cancel(cause);

      expect(job.getCancellationException(), same(cause));
    });

    test('keeps the first cause when cancelled twice', () {
      const first = CancellationException('first');

      final job = Job()
        ..cancel(first)
        ..cancel(const CancellationException('second'));

      expect(job.getCancellationException(), same(first));
    });

    test('wraps the failure of a failed job', () {
      final job = CompletableJob()..completeExceptionally(_boom);

      expect(
        job.getCancellationException(),
        isA<JobCancellationException>()
            .having((it) => it.cause, 'cause', same(_boom))
            .having((it) => it.message, 'message', 'Job was cancelled'),
      );
    });

    test('wraps the failure of a job that is still cancelling', () {
      final job = CompletableJob();
      final child = CompletableJob(job);
      final scope = CoroutineScope(child);
      final hold = Completer<void>();
      scope.launch((it) => hold.future, start: CoroutineStart.undispatched);

      job.completeExceptionally(_boom);
      final CancellationException cause = job.getCancellationException();
      hold.complete();

      expect(job.isCompleted, isFalse);
      expect(cause.cause, same(_boom));
    });

    test('says that a completed job completed normally', () {
      final job = CompletableJob()..complete();

      expect(
        job.getCancellationException(),
        isA<JobCancellationException>().having(
          (it) => it.message,
          'message',
          'Job has completed normally',
        ),
      );
    });
  });

  group('a job without a body', () {
    test('starts active', () {
      final job = Job();

      expect(job, isA<CompletableJob>());
      expect(job.isActive, isTrue);
      expect(job.isCompleted, isFalse);
      expect(job.isCancelled, isFalse);
      expect(job.start(), isFalse);
      expect(job.toString(), 'Job(active)');
    });

    test('completes at once without children', () {
      final job = CompletableJob();

      final bool first = job.complete();
      final bool second = job.complete();

      expect(first, isTrue);
      expect(second, isFalse);
      expect(job.toString(), 'Job(completed)');
    });

    test('is completing while a child runs', () {
      final job = CompletableJob();
      final child = CompletableJob(job);

      job.complete();
      final completing = job.toString();
      final bool active = job.isActive;
      child.complete();

      expect(completing, 'Job(completing)');
      expect(active, isTrue);
      expect(job.toString(), 'Job(completed)');
    });

    test('is cancelled at once by a cancel without children', () {
      final job = Job()..cancel();

      expect(job.toString(), 'Job(cancelled)');
      expect(job.isCompleted, isTrue);
    });

    test('ignores a complete once it is cancelled', () {
      final job = CompletableJob()..cancel();

      expect(job.complete(), isFalse);
      expect(job.completeExceptionally(_boom), isFalse);
      expect(job.isCancelled, isTrue);
    });

    test('ignores a cancel once it is completed', () {
      final job = CompletableJob()
        ..complete()
        ..cancel();

      expect(job.isCancelled, isFalse);
      expect(job.completeExceptionally(_boom), isFalse);
    });

    test('fails once with the first failure', () {
      final job = CompletableJob();

      final bool first = job.completeExceptionally(_boom);
      final bool second = job.completeExceptionally(StateError('later'));

      expect(first, isTrue);
      expect(second, isFalse);
      expect(job.isCancelled, isTrue);
      expect(job.toString(), 'Job(cancelled)');
    });

    test('is cancelled, not failed, by a cancellation', () {
      final causes = <Object?>[];
      final job = CompletableJob()
        ..invokeOnCompletion(causes.add)
        ..completeExceptionally(const CancellationException('stop'));

      expect(job.isCancelled, isTrue);
      expect(causes.single, isA<CancellationException>());
    });

    test('ignores a complete while completing', () {
      final job = CompletableJob();
      CompletableJob(job);

      final bool first = job.complete();
      final bool second = job.complete();
      final bool failed = job.completeExceptionally(_boom);

      expect(first, isTrue);
      expect(second, isFalse);
      expect(failed, isFalse);
    });
  });

  group('the job operations', () {
    test('throw the cause from ensureActive once cancelled', () {
      final job = Job()..cancel();

      expect(job.ensureActive, throwsA(isA<CancellationException>()));
      expect(Job().ensureActive, returnsNormally);
      expect(
        (CompletableJob()..complete()).ensureActive,
        throwsA(isA<JobCancellationException>()),
      );
    });

    test('cancel the children and not the job', () {
      final job = Job();
      final children = <Job>[Job(job), Job(job)];

      job.cancelChildren(const CancellationException('children'));

      expect(job.isActive, isTrue);
      expect(children.every((child) => child.isCancelled), isTrue);
      expect(job.children, isEmpty);
    });

    test(
      'cancel and join a job',
      () => runTest((it) async {
        final log = <String>[];
        final Job job = it.launch((it) async {
          try {
            await awaitCancellation();
          } finally {
            await withContext(
              NonCancellable.instance,
              (it) => delay(1.seconds),
            );
            log.add('cleaned up');
          }
        });
        it.runCurrent();

        await job.cancelAndJoin();

        expect(job.isCompleted, isTrue);
        expect(it.currentTime, 1.seconds);
        expect(log, hasLength(1));
      }),
    );

    test(
      'join every job one after another',
      () => runTest((it) async {
        final jobs = <Job>[
          for (var index = 1; index <= 3; index++)
            it.launch((it) => delay(Duration(seconds: index))),
        ];

        await jobs.joinAll();
        await <Job>[].joinAll();

        expect(jobs.every((job) => job.isCompleted), isTrue);
        expect(it.currentTime, 3.seconds);
      }),
    );
  });
}
