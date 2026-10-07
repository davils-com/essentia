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

/// Covers the completion handlers of a job and waiting for it: order,
/// causes, handlers registered late, removing them, handlers that throw,
/// and `join`.
void main() {
  group('a completion handler', () {
    test('runs in registration order once the job completes', () {
      final job = CompletableJob();
      final log = <String>[];
      job
        ..invokeOnCompletion((cause) => log.add('first $cause'))
        ..invokeOnCompletion((cause) => log.add('second $cause'))
        ..complete();

      expect(log, <String>['first null', 'second null']);
    });

    test('gets the cancellation of a cancelled job', () {
      const cause = CancellationException('stop');
      final job = Job();
      final causes = <Object?>[];
      job
        ..invokeOnCompletion(causes.add)
        ..cancel(cause);

      expect(causes, <Object?>[same(cause)]);
    });

    test('gets the failure of a failed job', () {
      final failure = StateError('broken');
      final job = CompletableJob();
      final causes = <Object?>[];
      job
        ..invokeOnCompletion(causes.add)
        ..completeExceptionally(failure);

      expect(causes, <Object?>[same(failure)]);
    });

    test('runs at once with the final cause when the job is complete', () {
      final failure = StateError('broken');
      final failed = CompletableJob()..completeExceptionally(failure);
      final completed = CompletableJob()..complete();
      final causes = <Object?>[];

      final Disposable first = failed.invokeOnCompletion(causes.add);
      completed
        ..invokeOnCompletion(causes.add)
        ..invokeOnCompletion(causes.add, onCancelling: true);
      first.dispose();

      expect(causes, <Object?>[same(failure), null, null]);
    });

    test('waits for the children before it runs', () {
      final job = CompletableJob();
      final child = CompletableJob(job);
      final log = <String>[];
      job
        ..invokeOnCompletion((cause) => log.add('job'))
        ..complete();
      final whileCompleting = List<String>.of(log);

      child.complete();

      expect(whileCompleting, isEmpty);
      expect(log, <String>['job']);
    });

    test('never runs once it was disposed', () {
      final job = CompletableJob();
      final log = <String>[];
      job.invokeOnCompletion((cause) => log.add('removed'))
        ..dispose()
        ..dispose();
      job
        ..invokeOnCompletion((cause) => log.add('kept'))
        ..complete();

      expect(log, <String>['kept']);
    });

    test('is not affected by a dispose after it ran', () {
      final job = CompletableJob();
      final log = <String>[];
      final Disposable registration = job.invokeOnCompletion(
        (cause) => log.add('ran'),
      );

      job.complete();
      registration.dispose();

      expect(log, <String>['ran']);
    });
  });

  group('a cancelling handler', () {
    test(
      'runs as soon as the job starts to be cancelled',
      () => runTest((it) {
        final log = <String>[];
        final hold = Completer<void>();
        final Job job =
            it.launch((it) async {
                try {
                  await awaitCancellation();
                } finally {
                  await hold.future;
                }
              })
              ..invokeOnCompletion(
                (cause) => log.add('cancelling ${cause.runtimeType}'),
                onCancelling: true,
              )
              ..invokeOnCompletion(
                (cause) => log.add('completed ${cause.runtimeType}'),
              );
        it.runCurrent();

        job.cancel();
        it.runCurrent();
        final whileCancelling = List<String>.of(log);
        hold.complete();
        it.runCurrent();

        expect(whileCancelling, <String>[
          'cancelling JobCancellationException',
        ]);
        expect(log, <String>[
          'cancelling JobCancellationException',
          'completed JobCancellationException',
        ]);
      }),
    );

    test(
      'runs at once with the root cause on a cancelling job',
      () => runTest((it) {
        final hold = Completer<void>();
        final Job job = it.launch((it) async {
          try {
            await awaitCancellation();
          } finally {
            await hold.future;
          }
        });
        it.runCurrent();
        const cause = CancellationException('stop');
        job.cancel(cause);
        final causes = <Object?>[];

        job
          ..invokeOnCompletion(causes.add, onCancelling: true)
          ..invokeOnCompletion(causes.add);
        final early = List<Object?>.of(causes);
        hold.complete();
        it.runCurrent();

        expect(early, <Object?>[same(cause)]);
        expect(causes, <Object?>[same(cause), same(cause)]);
      }),
    );

    test('runs once, with null, when the job completes normally', () {
      final job = CompletableJob();
      final causes = <Object?>[];
      job
        ..invokeOnCompletion(causes.add, onCancelling: true)
        ..complete();

      expect(causes, <Object?>[null]);
    });

    test('runs only once when the job is cancelled and completes', () {
      final job = Job();
      final causes = <Object?>[];
      job
        ..invokeOnCompletion(causes.add, onCancelling: true)
        ..cancel()
        ..cancel();

      expect(causes, hasLength(1));
    });

    test('never runs once it was disposed', () {
      final job = Job();
      final log = <String>[];
      job
          .invokeOnCompletion((cause) => log.add('ran'), onCancelling: true)
          .dispose();

      job.cancel();

      expect(log, isEmpty);
    });
  });

  group('a handler that throws', () {
    test('is reported to the zone and the other handlers still run', () {
      final job = Job();
      final log = <String>[];
      final errors = <Object>[];
      job
        ..invokeOnCompletion((cause) => throw const FormatException('broken'))
        ..invokeOnCompletion(
          (cause) => throw const FormatException('early'),
          onCancelling: true,
        )
        ..invokeOnCompletion((cause) => log.add('second'));

      runZonedGuarded(job.cancel, (error, stackTrace) => errors.add(error));

      expect(log, <String>['second']);
      expect(errors, <Matcher>[
        isA<CompletionHandlerException>().having(
          (it) => it.cause,
          'cause',
          isA<FormatException>().having((it) => it.message, 'm', 'early'),
        ),
        isA<CompletionHandlerException>().having(
          (it) => it.cause,
          'cause',
          isA<FormatException>().having((it) => it.message, 'm', 'broken'),
        ),
      ]);
      expect(job.isCancelled, isTrue);
    });

    test(
      'of a coroutine is reported to its exception handler',
      () => runTest((it) async {
        final reported = <Object>[];
        final Job job = it.launch(
          (it) {},
          context: CoroutineExceptionHandler(
            (context, error, stackTrace) => reported.add(error),
          ),
        )..invokeOnCompletion((cause) => throw StateError('handler'));

        await job.join();

        expect(reported, <Matcher>[
          isA<CompletionHandlerException>().having(
            (it) => it.cause,
            'cause',
            isStateError,
          ),
        ]);
      }),
    );
  });

  group('join', () {
    test(
      'waits until the job is complete without throwing its failure',
      () => runTest((it) async {
        final scope = CoroutineScope(
          SupervisorJob() +
              CoroutineExceptionHandler((context, error, stackTrace) {}),
        );
        final Job job = scope.launch((it) async {
          await delay(1.seconds);
          throw StateError('failed');
        });

        await job.join();

        expect(job.isCancelled, isTrue);
        expect(it.currentTime, 1.seconds);
      }),
    );

    test(
      'returns at once for a complete job',
      () => runTest((it) async {
        final job = CompletableJob()..complete();

        await job.join();

        expect(it.currentTime, Duration.zero);
      }),
    );

    test(
      'throws inside a cancelled job even for a complete job',
      () => runTest((it) async {
        final done = CompletableJob()..complete();
        final Deferred<void> joining = it.async((it) {
          it.cancel();
          return done.join();
        });

        await expectLater(joining, throwsA(isA<CancellationException>()));
      }),
    );

    test(
      'starts a lazily started coroutine',
      () => runTest((it) async {
        final log = <String>[];
        final Job job = it.launch(
          (it) => log.add('ran'),
          start: CoroutineStart.lazy,
        );
        it.runCurrent();
        final before = List<String>.of(log);

        await job.join();

        expect(before, isEmpty);
        expect(log, <String>['ran']);
      }),
    );

    test(
      'is cancellable and leaves the joined job alone',
      () => runTest((it) async {
        final other = CompletableJob();
        final Deferred<void> joining = it.async((it) => other.join());
        it.runCurrent();

        joining.cancel();

        await expectLater(joining, throwsA(isA<CancellationException>()));
        expect(other.isActive, isTrue);
        other.complete();
      }),
    );
  });
}
