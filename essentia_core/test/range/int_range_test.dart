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

import 'dart:math';

import 'package:essentia_core/src/range/closed_range.dart';
import 'package:essentia_core/src/range/int_progression.dart';
import 'package:test/test.dart';

/// The seed of every random source, so that picks repeat.
const _seed = 7;

/// Covers the integer range, its random picks and its description.
void main() {
  test('yields every integer between its ends', () {
    const range = IntRange(1, 4);

    final List<int> values = range.toList();

    expect(values, <int>[1, 2, 3, 4]);
  });

  test('serves as a closed range', () {
    const ClosedRange<int> range = IntRange(1, 4);

    final bool contained = range.contains(4);

    expect(contained, isTrue);
  });

  test('picks a random element within its ends', () {
    const range = IntRange(10, 12);

    final int value = range.random(Random(_seed));

    expect(range.contains(value), isTrue);
  });

  test('picks a random element without a given source', () {
    const range = IntRange(10, 10);

    final int value = range.random();

    expect(value, 10);
  });

  test('refuses a random element of an empty range', () {
    const range = IntRange(3, 1);

    int pick() => range.random();

    expect(pick, throwsStateError);
  });

  test(
    'refuses a random element of a range longer than a random source draws',
    () {
      const range = IntRange(0, 0x200000000);

      int pick() => range.random();

      expect(pick, throwsRangeError);
    },
  );

  test('picks nothing at random from an empty range', () {
    const range = IntRange(3, 1);

    final int? value = range.randomOrNull();

    expect(value, isNull);
  });

  test('picks a random element when the range is not empty', () {
    const range = IntRange(5, 5);

    final int? value = range.randomOrNull(Random(_seed));

    expect(value, 5);
  });

  test('describes itself with both ends', () {
    const range = IntRange(1, 4);

    final description = range.toString();

    expect(description, '1..4');
  });
}
