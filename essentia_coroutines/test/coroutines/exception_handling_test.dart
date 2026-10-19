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

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:test/test.dart';

/// Covers where an unhandled failure of a coroutine goes: the
/// `CoroutineExceptionHandler` of its context, the zone it was started in
/// when there is none or the handler throws, and nowhere for a
/// cancellation.
void main() {
  group('handleCoroutineException', () {
    test('hands the failure to the handler of the context', () {
      final seen = <String>[];
      final failure = StateError('broken');
      final CoroutineContext context =
          const CoroutineName('worker') +
          CoroutineExceptionHandler((context, error, stackTrace) {
            seen.add(
              '${context.get(CoroutineName.key)?.name} '
              '${identical(error, failure)}',
            );
          });

      handleCoroutineException(context, failure, StackTrace.current);

      expect(seen, <String>['worker true']);
    });

    test('never reports a cancellation', () {
      final seen = <Object>[];
      final errors = <Object>[];

      runZonedGuarded(() {
        handleCoroutineException(
          CoroutineExceptionHandler(
            (context, error, stackTrace) => seen.add(error),
          ),
          const CancellationException(),
          StackTrace.current,
        );
        handleCoroutineException(
          CoroutineContext.empty,
          const CancellationException(),
          StackTrace.current,
        );
      }, (error, stackTrace) => errors.add(error));

      expect(seen, isEmpty);
      expect(errors, isEmpty);
    });

    test('reports to the current zone without a handler', () {
      final errors = <Object>[];
      final failure = StateError('broken');

      runZonedGuarded(
        () => handleCoroutineException(
          CoroutineContext.empty,
          failure,
          StackTrace.current,
        ),
        (error, stackTrace) => errors.add(error),
      );

      expect(errors, <Object>[failure]);
    });

    test('reports to the zone it is given', () {
      final errors = <Object>[];
      final failure = StateError('broken');
      final Zone zone = Zone.current.fork(
        specification: ZoneSpecification(
          handleUncaughtError: (self, parent, zone, error, stackTrace) =>
              errors.add(error),
        ),
      );

      handleCoroutineException(
        CoroutineContext.empty,
        failure,
        StackTrace.current,
        zone: zone,
      );

      expect(errors, <Object>[failure]);
    });

    test('reports a handler that throws, with the failure suppressed', () {
      final errors = <Object>[];
      final failure = StateError('broken');
      final handlerFailure = ArgumentError('handler broken');

      runZonedGuarded(
        () => handleCoroutineException(
          CoroutineExceptionHandler(
            (context, error, stackTrace) => throw handlerFailure,
          ),
          failure,
          StackTrace.current,
        ),
        (error, stackTrace) => errors.add(error),
      );

      expect(errors, <Object>[handlerFailure]);
      expect(suppressedExceptionsOf(handlerFailure), <Object>[failure]);
    });
  });

  group('a coroutine', () {
    test('reports an unhandled failure to its exception handler', () async {
      final seen = <Object>[];
      final failure = StateError('broken');
      final scope = CoroutineScope(
        SupervisorJob() +
            CoroutineExceptionHandler(
              (context, error, stackTrace) => seen.add(error),
            ),
      );

      await scope.launch((it) => throw failure).join();

      expect(seen, <Object>[failure]);
    });

    test('reports to the zone it was started in without a handler', () async {
      final errors = <Object>[];
      final failure = StateError('broken');
      final done = Completer<void>();

      runZonedGuarded(() {
        CoroutineScope(SupervisorJob())
            .launch((it) async {
              await Future<void>.delayed(Duration.zero);
              throw failure;
            })
            .invokeOnCompletion((cause) => done.complete());
      }, (error, stackTrace) => errors.add(error));
      await done.future;

      expect(errors, <Object>[failure]);
    });

    test('never reports its cancellation', () async {
      final seen = <Object>[];
      final scope = CoroutineScope(
        SupervisorJob() +
            CoroutineExceptionHandler(
              (context, error, stackTrace) => seen.add(error),
            ),
      );
      final Job job = scope.launch((it) => awaitCancellation());
      await Future<void>.delayed(Duration.zero);

      await job.cancelAndJoin();
      await scope
          .launch((it) => throw const CancellationException('own'))
          .join();

      expect(seen, isEmpty);
    });

    test('started with async never reports its failure', () async {
      final seen = <Object>[];
      final scope = CoroutineScope(
        SupervisorJob() +
            CoroutineExceptionHandler(
              (context, error, stackTrace) => seen.add(error),
            ),
      );

      final Deferred<int> failed = scope.async((it) => throw StateError('x'));
      await failed.join();

      expect(seen, isEmpty);
      expect(failed.getCompletionExceptionOrNull(), isStateError);
    });

    test('of the global scope reports to its handler', () async {
      final seen = <Object>[];

      await GlobalScope.instance
          .launch(
            (it) => throw StateError('global'),
            context: CoroutineExceptionHandler(
              (context, error, stackTrace) => seen.add(error),
            ),
          )
          .join();

      expect(seen, <Matcher>[isStateError]);
    });

    test('names the handler', () {
      expect(
        CoroutineExceptionHandler((context, error, stackTrace) {}).toString(),
        'CoroutineExceptionHandler',
      );
      expect(
        CoroutineExceptionHandler((context, error, stackTrace) {}).contextKey,
        same(CoroutineExceptionHandler.key),
      );
    });
  });
}
