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
import 'package:essentia_core/src/result/result_future.dart';
import 'package:test/test.dart';

/// The error the failures of these tests carry.
const _bad = FormatException('bad');

/// Covers [ResultFuture], which captures the outcome of a future.
void main() {
  test('turns a future that completes with a value into a success', () async {
    final future = Future<int>.value(7);

    final Result<int> result = await future.toResult();

    expect(result, const Success<int>(7));
  });

  test('turns a future that completes with an error into a failure', () async {
    final future = Future<int>.error(_bad, StackTrace.empty);

    final Result<int> result = await future.toResult();

    expect(result.errorOrNull, same(_bad));
  });

  test(
    'keeps the stack trace of a future that completed with an error',
    () async {
      final future = Future<int>.error(_bad, StackTrace.current);

      final Result<int> result = await future.toResult();

      expect(result.stackTraceOrNull, isNot(StackTrace.empty));
    },
  );
}
