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
import 'package:essentia_core/src/result/result_iterable.dart';
import 'package:test/test.dart';

/// The error the failures of these tests carry.
const _bad = FormatException('bad');

/// A second error, to tell two failures apart.
const _worse = FormatException('worse');

/// Two successes and two failures, interleaved.
const _mixed = <Result<int>>[
  Success<int>(1),
  Failure<int>(_bad),
  Success<int>(2),
  Failure<int>(_worse),
];

/// Covers [ResultIterable], which splits and combines a collection of
/// results.
void main() {
  test('collects the values of every success', () {
    final List<int> collected = _mixed.values;

    final matches = collected.join() == '12';

    expect(matches, isTrue);
  });

  test('collects the errors of every failure', () {
    final List<Object> collected = _mixed.errors;

    expect(collected, [_bad, _worse]);
  });

  test('refuses to modify the values it collected', () {
    final List<int> collected = _mixed.values;

    void add() => collected.add(3);

    expect(add, throwsUnsupportedError);
  });

  test('refuses to modify the errors it collected', () {
    final List<Object> collected = _mixed.errors;

    void add() => collected.add(_bad);

    expect(add, throwsUnsupportedError);
  });

  test('splits a mixed list into its values and its errors', () {
    final (:List<int> values, :List<Object> errors) = _mixed.partition();

    expect(
      [values, errors],
      [
        [1, 2],
        [_bad, _worse],
      ],
    );
  });

  test('sequences a list without failures into a list of values', () {
    const results = <Result<int>>[Success<int>(1), Success<int>(2)];

    final Result<List<int>> sequenced = results.sequence();

    expect(sequenced.valueOrNull, [1, 2]);
  });

  test('sequences a list with failures into its first failure', () {
    final Result<List<int>> sequenced = _mixed.sequence();

    expect(sequenced.errorOrNull, same(_bad));
  });

  test('sequences an empty list into an empty list of values', () {
    const results = <Result<int>>[];

    final Result<List<int>> sequenced = results.sequence();

    expect(sequenced.valueOrNull, isEmpty);
  });
}
