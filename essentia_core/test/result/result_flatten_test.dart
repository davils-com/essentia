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
import 'package:essentia_core/src/result/result_flatten.dart';
import 'package:test/test.dart';

/// The error the failures of these tests carry.
const _bad = FormatException('bad');

/// Covers [ResultFlatten], which collapses a result that carries a result.
void main() {
  test('collapses a success that carries a success', () {
    const Result<Result<int>> nested = Success<Result<int>>(Success<int>(7));

    final Result<int> flattened = nested.flatten();

    expect(flattened, const Success<int>(7));
  });

  test('collapses a success that carries a failure', () {
    const Result<Result<int>> nested = Success<Result<int>>(Failure<int>(_bad));

    final Result<int> flattened = nested.flatten();

    expect(flattened.errorOrNull, same(_bad));
  });

  test('collapses an outer failure into a failure', () {
    const Result<Result<int>> nested = Failure<Result<int>>(_bad);

    final Result<int> flattened = nested.flatten();

    expect(flattened.errorOrNull, same(_bad));
  });
}
