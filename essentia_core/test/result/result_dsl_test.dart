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

/// The error the failures of these tests carry.
const _bad = FormatException('bad');

/// Covers [runCatching] and [runCatchingAsync].
void main() {
  test('returns a success when the block returns a value', () {
    final Result<int> result = runCatching(() => 7);

    final int? value = result.valueOrNull;

    expect(value, 7);
  });

  test('returns a failure when the block throws an exception', () {
    final Result<int> result = runCatching<int>(() => throw _bad);

    final Object? error = result.errorOrNull;

    expect(error, _bad);
  });

  test('returns a failure when the block throws an error', () {
    final Result<int> result = runCatching<int>(() => throw StateError('boom'));

    final Object? error = result.errorOrNull;

    expect(error, isA<StateError>());
  });

  test('keeps the stack trace of the error that the block threw', () {
    final Result<int> result = runCatching<int>(() => throw _bad);

    final StackTrace? stackTrace = result.stackTraceOrNull;

    expect(stackTrace, isNot(StackTrace.empty));
  });

  test('catches nothing when the awaited block returns a value', () async {
    final Result<int> result = await runCatchingAsync(() async => 7);

    expect(result, const Success<int>(7));
  });

  test('catches what the awaited block throws', () async {
    final Result<int> result = await runCatchingAsync<int>(
      () async => throw _bad,
    );

    expect(result.errorOrNull, same(_bad));
  });
}
