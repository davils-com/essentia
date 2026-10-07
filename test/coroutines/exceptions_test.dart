/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:essentia/testing.dart';
import 'package:test/test.dart';

/// Covers the exceptions of the coroutines: how they render, what they
/// carry and how failures are recorded beside each other.
void main() {
  group('CancellationException', () {
    test('renders without a message', () {
      expect(const CancellationException().toString(), 'CancellationException');
    });

    test('renders with its message', () {
      expect(
        const CancellationException('user left').toString(),
        'CancellationException: user left',
      );
    });

    test('is an exception, not an error', () {
      expect(const CancellationException(), isA<Exception>());
    });

    test('carries the failure behind it', () {
      const cause = FormatException();

      expect(const CancellationException('failed', cause).cause, cause);
    });
  });

  group('JobCancellationException', () {
    test('renders its message, its job and its cause', () {
      final job = Job();
      const cause = FormatException('broken');

      final exception = JobCancellationException(
        'Job was cancelled',
        job: job,
        cause: cause,
      );

      expect(exception, isA<CancellationException>());
      expect(exception.job, same(job));
      expect(exception.cause, same(cause));
      expect(
        exception.toString(),
        'JobCancellationException: Job was cancelled; job=Job(active); '
        'cause=FormatException: broken',
      );
    });

    test('renders without a job or a cause', () {
      expect(
        JobCancellationException('gone').toString(),
        'JobCancellationException: gone',
      );
    });

    test('is what a cancel without a cause hands out', () {
      final job = Job()..cancel();

      final CancellationException cause = job.getCancellationException();

      expect(
        cause,
        isA<JobCancellationException>()
            .having((it) => it.message, 'message', 'Job was cancelled')
            .having((it) => it.job, 'job', same(job)),
      );
    });
  });

  group('TimeoutCancellationException', () {
    test('renders its message', () {
      expect(
        const TimeoutCancellationException('Timed out').toString(),
        'TimeoutCancellationException: Timed out',
      );
    });

    test(
      'names the timeout that passed',
      () => runTest((it) async {
        final Future<void> timedOut = withTimeout(
          5.milliseconds,
          (it) => delay(1.seconds),
        );

        await expectLater(
          timedOut,
          throwsA(
            isA<TimeoutCancellationException>().having(
              (it) => it.message,
              'message',
              'Timed out waiting for 5 ms',
            ),
          ),
        );
      }),
    );
  });

  group('CompletionHandlerException', () {
    test('renders the failure of the handler', () {
      final StackTrace stackTrace = StackTrace.current;

      final exception = CompletionHandlerException(
        const FormatException('broken'),
        stackTrace,
      );

      expect(exception.cause, isFormatException);
      expect(exception.stackTrace, same(stackTrace));
      expect(
        exception.toString(),
        'CompletionHandlerException: Exception in completion handler: '
        'FormatException: broken',
      );
    });
  });

  group('suppressed exceptions', () {
    test('are empty for an error nobody recorded anything beside', () {
      expect(suppressedExceptionsOf(StateError('alone')), isEmpty);
    });

    test('are empty for an error that cannot carry any', () {
      expect(suppressedExceptionsOf('text'), isEmpty);
      expect(suppressedExceptionsOf(42), isEmpty);
      expect(suppressedExceptionsOf(true), isEmpty);
      expect(suppressedExceptionsOf((1, 2)), isEmpty);
    });

    test(
      'record the later failures of a scope beside the first one',
      () => runTest((it) async {
        final first = StateError('first');
        final second = StateError('second');
        final third = StateError('third');

        final Future<void> failed = _failTogether(first, <StateError>[
          second,
          third,
        ]);

        await expectLater(failed, throwsA(same(first)));
        expect(suppressedExceptionsOf(first), <Object>[second, third]);
      }),
    );

    test(
      'never record a failure beside itself',
      () => runTest((it) async {
        final first = StateError('first');

        final Future<void> failed = _failTogether(first, <StateError>[first]);

        await expectLater(failed, throwsA(same(first)));
        expect(suppressedExceptionsOf(first), isEmpty);
      }),
    );

    test(
      'are a copy that cannot be changed',
      () => runTest((it) async {
        final first = StateError('first');

        await expectLater(
          _failTogether(first, <StateError>[StateError('second')]),
          throwsA(same(first)),
        );
        expect(
          () => suppressedExceptionsOf(first).add('more'),
          throwsUnsupportedError,
        );
      }),
    );
  });
}

/// Fails a scope with [first] after a second, while children that wait
/// throw each of [later] once they are cancelled.
///
/// Returns the future of the scope.
Future<void> _failTogether(StateError first, List<StateError> later) =>
    coroutineScope((it) {
      for (final failure in later) {
        it.launch((it) async {
          try {
            await awaitCancellation();
          } on CancellationException {
            throw failure;
          }
        });
      }
      it.launch((it) async {
        await delay(1.seconds);
        throw first;
      });
    });
