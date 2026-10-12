/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/result/result.dart';
import 'package:essentia_core/src/result/result_dsl.dart';
import 'package:test/test.dart';

import 'caught_stack_trace.dart';
import 'probe_log.dart';

/// The error the failures of these tests carry.
const _bad = FormatException('bad');

/// Covers [Result], [Success] and [Failure]: construction, queries,
/// unwrapping, equality, rendering and every transformation.
void main() {
  test('wraps a value in a success', () {
    const Result<int> result = Result.success(7);

    final int? value = result.valueOrNull;

    expect(value, 7);
  });

  test('wraps an error in a failure', () {
    const Result<int> result = Result.failure(_bad);

    final Object? error = result.errorOrNull;

    expect(error, _bad);
  });

  test(
    'defaults the stack trace of a manually built failure to the empty one',
    () {
      const Result<int> result = Result.failure(_bad);

      final StackTrace? stackTrace = result.stackTraceOrNull;

      expect(stackTrace, StackTrace.empty);
    },
  );

  test('reports a success as successful', () {
    const Result<int> result = Success<int>(7);

    final bool successful = result.isSuccess;

    expect(successful, isTrue);
  });

  test('reports a failure as not successful', () {
    const Result<int> result = Failure<int>(_bad);

    final bool successful = result.isSuccess;

    expect(successful, isFalse);
  });

  test('reports a failure as failed', () {
    const Result<int> result = Failure<int>(_bad);

    final bool failed = result.isFailure;

    expect(failed, isTrue);
  });

  test('reports a success as not failed', () {
    const Result<int> result = Success<int>(7);

    final bool failed = result.isFailure;

    expect(failed, isFalse);
  });

  test('hands out no value for a failure', () {
    const Result<int> result = Failure<int>(_bad);

    final int? value = result.valueOrNull;

    expect(value, isNull);
  });

  test('hands out no error for a success', () {
    const Result<int> result = Success<int>(7);

    final Object? error = result.errorOrNull;

    expect(error, isNull);
  });

  test('hands out no stack trace for a success', () {
    const Result<int> result = Success<int>(7);

    final StackTrace? stackTrace = result.stackTraceOrNull;

    expect(stackTrace, isNull);
  });

  test('returns the value when a success is unwrapped', () {
    const Result<int> result = Success<int>(7);

    final int value = result.getOrThrow();

    expect(value, 7);
  });

  test('throws the original error when a failure is unwrapped', () {
    const Result<int> result = Failure<int>(_bad);

    int unwrap() => result.getOrThrow();

    expect(unwrap, throwsA(same(_bad)));
  });

  test('throws with the original stack trace when a failure is unwrapped', () {
    final Result<int> result = runCatching<int>(() => throw _bad);

    final StackTrace thrown = caughtStackTrace(result.getOrThrow);

    expect('$thrown', '${result.stackTraceOrNull}');
  });

  test('returns the value instead of the default for a success', () {
    const Result<int> result = Success<int>(7);

    final int value = result.getOrDefault(0);

    expect(value, 7);
  });

  test('returns the default for a failure', () {
    const Result<int> result = Failure<int>(_bad);

    final int value = result.getOrDefault(0);

    expect(value, 0);
  });

  test('returns the value without building a fallback for a success', () {
    const Result<int> result = Success<int>(7);

    final int value = result.getOrElse((error, stackTrace) => 0);

    expect(value, 7);
  });

  test('builds the fallback from the error of a failure', () {
    const Result<String> result = Failure<String>(_bad);

    final String value = result.getOrElse((error, stackTrace) => '$error');

    expect(value, '$_bad');
  });

  test('treats two successes with the same value as equal', () {
    const first = Success<int>(7);
    const second = Success<int>(7);

    final areEqual = first == second;

    expect(areEqual, isTrue);
  });

  test('treats two successes with different values as unequal', () {
    const first = Success<int>(7);
    const second = Success<int>(8);

    final areEqual = first == second;

    expect(areEqual, isFalse);
  });

  test('shares its hash code with an equal success', () {
    const first = Success<int>(7);
    const second = Success<int>(7);

    final hash = first.hashCode;

    expect(hash, second.hashCode);
  });

  test('renders a success with its value', () {
    const result = Success<int>(7);

    final rendered = '$result';

    expect(rendered, 'Success(7)');
  });

  test('treats two failures with the same error and stack trace as equal', () {
    const first = Failure<int>(_bad);
    const second = Failure<int>(_bad);

    final areEqual = first == second;

    expect(areEqual, isTrue);
  });

  test('treats two failures with different errors as unequal', () {
    const first = Failure<int>(_bad);
    const second = Failure<int>(FormatException('worse'));

    final areEqual = first == second;

    expect(areEqual, isFalse);
  });

  test('treats two failures with different stack traces as unequal', () {
    const first = Failure<int>(_bad);
    final Result<int> second = runCatching<int>(() => throw _bad);

    final areEqual = first == second;

    expect(areEqual, isFalse);
  });

  test('shares its hash code with an equal failure', () {
    const first = Failure<int>(_bad);
    const second = Failure<int>(_bad);

    final hash = first.hashCode;

    expect(hash, second.hashCode);
  });

  test('renders a failure with its error', () {
    const result = Failure<int>(_bad);

    final rendered = '$result';

    expect(rendered, 'Failure($_bad)');
  });

  test('selects the success branch when matched by pattern', () {
    const Result<int> result = Success<int>(7);

    final String branch = switch (result) {
      Success<int>(:final int value) => 'value $value',
      Failure<int>() => 'failure',
    };

    expect(branch, 'value 7');
  });

  test('selects the failure branch when matched by pattern', () {
    const Result<int> result = Failure<int>(_bad);

    final String branch = switch (result) {
      Success<int>() => 'value',
      Failure<int>(:final Object error) => 'failure $error',
    };

    expect(branch, 'failure $_bad');
  });

  test('folds a success through its success branch', () {
    const Result<int> result = Success<int>(7);

    final String folded = result.fold(
      onSuccess: (value) => 'value $value',
      onFailure: (error, stackTrace) => 'error $error',
    );

    expect(folded, 'value 7');
  });

  test('folds a failure through its failure branch', () {
    const Result<int> result = Failure<int>(_bad);

    final String folded = result.fold(
      onSuccess: (value) => 'value $value',
      onFailure: (error, stackTrace) => 'error $error',
    );

    expect(folded, 'error $_bad');
  });

  test('maps the value of a success', () {
    const Result<int> result = Success<int>(7);

    final Result<String> mapped = result.map((value) => 'value $value');

    expect(mapped, const Success<String>('value 7'));
  });

  test('keeps the error and the stack trace when a failure is mapped', () {
    final Result<int> result = runCatching<int>(() => throw _bad);

    final Result<String> mapped = result.map((value) => 'value $value');

    expect(mapped.stackTraceOrNull, same(result.stackTraceOrNull));
  });

  test('never calls the transform when a failure is mapped', () {
    const Result<int> result = Failure<int>(_bad);
    final log = ProbeLog();

    result.map((value) => log.record('$value'));

    expect(log.entries, isEmpty);
  });

  test('lets an error of the transform through when mapping', () {
    const Result<int> result = Success<int>(7);

    Result<String> mapIt() => result.map((value) => throw _bad);

    expect(mapIt, throwsA(same(_bad)));
  });

  test('catches an error of the transform when mapping and catching', () {
    const Result<int> result = Success<int>(7);

    final Result<String> mapped = result.mapCatching((value) => throw _bad);

    expect(mapped.errorOrNull, same(_bad));
  });

  test('maps the value of a success when mapping and catching', () {
    const Result<int> result = Success<int>(7);

    final Result<String> mapped = result.mapCatching((value) => '$value');

    expect(mapped, const Success<String>('7'));
  });

  test('keeps the failure when mapping and catching', () {
    const Result<int> result = Failure<int>(_bad);

    final Result<String> mapped = result.mapCatching((value) => '$value');

    expect(mapped.errorOrNull, same(_bad));
  });

  test('turns a failure into a success when recovering', () {
    const Result<int> result = Failure<int>(_bad);

    final Result<int> recovered = result.recover((error, stackTrace) => 0);

    expect(recovered, const Success<int>(0));
  });

  test('leaves a success untouched when recovering', () {
    const Result<int> result = Success<int>(7);

    final Result<int> recovered = result.recover((error, stackTrace) => 0);

    expect(recovered, same(result));
  });

  test('lets an error of the recovery through when recovering', () {
    const Result<int> result = Failure<int>(_bad);

    Result<int> recoverIt() =>
        result.recover((error, stackTrace) => throw StateError('worse'));

    expect(recoverIt, throwsA(isA<StateError>()));
  });

  test('catches an error of the recovery when recovering and catching', () {
    const Result<int> result = Failure<int>(_bad);

    final Result<int> recovered = result.recoverCatching(
      (error, stackTrace) => throw StateError('worse'),
    );

    expect(recovered.errorOrNull, isA<StateError>());
  });

  test('turns a failure into a success when recovering and catching', () {
    const Result<int> result = Failure<int>(_bad);

    final Result<int> recovered = result.recoverCatching(
      (error, stackTrace) => 0,
    );

    expect(recovered, const Success<int>(0));
  });

  test('leaves a success untouched when recovering and catching', () {
    const Result<int> result = Success<int>(7);

    final Result<int> recovered = result.recoverCatching(
      (error, stackTrace) => 0,
    );

    expect(recovered, same(result));
  });

  test('runs the action of a success and hands back the same result', () {
    final log = ProbeLog();
    const Result<int> result = Success<int>(7);

    final Result<int> observed = result.onSuccess(
      (value) => log.record('$value'),
    );

    expect(
      [log.entries, identical(observed, result)],
      [
        ['7'],
        true,
      ],
    );
  });

  test('skips the success action of a failure', () {
    final log = ProbeLog();
    const Result<int> result = Failure<int>(_bad);

    final Result<int> observed = result.onSuccess(
      (value) => log.record('$value'),
    );

    expect([log.entries, identical(observed, result)], [<String>[], true]);
  });

  test('runs the action of a failure and hands back the same result', () {
    final log = ProbeLog();
    const Result<int> result = Failure<int>(_bad);

    final Result<int> observed = result.onFailure(
      (error, stackTrace) => log.record('$error'),
    );

    expect(
      [log.entries, identical(observed, result)],
      [
        ['$_bad'],
        true,
      ],
    );
  });

  test('skips the failure action of a success', () {
    final log = ProbeLog();
    const Result<int> result = Success<int>(7);

    final Result<int> observed = result.onFailure(
      (error, stackTrace) => log.record('$error'),
    );

    expect([log.entries, identical(observed, result)], [<String>[], true]);
  });

  test('chains a success into the result the transform returns', () {
    const Result<int> result = Success<int>(7);

    final Result<String> chained = result.flatMap(
      (value) => Success<String>('value $value'),
    );

    expect(chained, const Success<String>('value 7'));
  });

  test('chains a success into a failure the transform returns', () {
    const Result<int> result = Success<int>(7);

    final Result<String> chained = result.flatMap(
      (value) => const Failure<String>(_bad),
    );

    expect(chained.errorOrNull, same(_bad));
  });

  test('keeps the error and the stack trace when a failure is chained', () {
    final Result<int> result = runCatching<int>(() => throw _bad);

    final Result<String> chained = result.flatMap(
      (value) => Success<String>('value $value'),
    );

    expect(chained.stackTraceOrNull, same(result.stackTraceOrNull));
  });

  test('replaces the error of a failure and keeps its stack trace', () {
    final Result<int> result = runCatching<int>(() => throw _bad);

    final Result<int> relabelled = result.mapError(
      (error, stackTrace) => StateError('$error'),
    );

    expect(
      [relabelled.errorOrNull, relabelled.stackTraceOrNull],
      [isA<StateError>(), same(result.stackTraceOrNull)],
    );
  });

  test('leaves a success untouched when its error is mapped', () {
    const Result<int> result = Success<int>(7);

    final Result<int> relabelled = result.mapError(
      (error, stackTrace) => StateError('$error'),
    );

    expect(relabelled, same(result));
  });

  test('zips two successes into a pair', () {
    const Result<int> first = Success<int>(7);
    const Result<String> second = Success<String>('seven');

    final Result<(int, String)> zipped = first.zip(second);

    expect(zipped, const Success<(int, String)>((7, 'seven')));
  });

  test('zips into the failure of its left side', () {
    const Result<int> first = Failure<int>(_bad);
    const Result<String> second = Success<String>('seven');

    final Result<(int, String)> zipped = first.zip(second);

    expect(zipped.errorOrNull, same(_bad));
  });

  test('zips into the failure of its right side', () {
    const Result<int> first = Success<int>(7);
    const Result<String> second = Failure<String>(_bad);

    final Result<(int, String)> zipped = first.zip(second);

    expect(zipped.errorOrNull, same(_bad));
  });

  test('maps the value of a success asynchronously', () async {
    const Result<int> result = Success<int>(7);

    final Result<String> mapped = await result.mapAsync(
      (value) async => 'value $value',
    );

    expect(mapped, const Success<String>('value 7'));
  });

  test('keeps a failure when it is mapped asynchronously', () async {
    const Result<int> result = Failure<int>(_bad);

    final Result<String> mapped = await result.mapAsync(
      (value) async => 'value $value',
    );

    expect(mapped.errorOrNull, same(_bad));
  });

  test('lets an error of the asynchronous transform through when mapping', () {
    const Result<int> result = Success<int>(7);

    Future<Result<String>> mapIt() =>
        result.mapAsync((value) async => throw _bad);

    expect(mapIt, throwsA(same(_bad)));
  });

  test(
    'chains a success into the result the awaited transform returns',
    () async {
      const Result<int> result = Success<int>(7);

      final Result<String> chained = await result.flatMapAsync(
        (value) async => Success<String>('value $value'),
      );

      expect(chained, const Success<String>('value 7'));
    },
  );

  test('keeps a failure when it is chained asynchronously', () async {
    const Result<int> result = Failure<int>(_bad);

    final Result<String> chained = await result.flatMapAsync(
      (value) async => Success<String>('value $value'),
    );

    expect(chained.errorOrNull, same(_bad));
  });
}
