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
