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

import 'package:essentia_core/src/comparison/comparable_coercion.dart';
import 'package:essentia_core/src/range/closed_range.dart';
import 'package:essentia_core/src/range/int_progression.dart';
import 'package:essentia_core/src/range/int_range_building.dart';
import 'package:test/test.dart';

import 'version.dart';

/// Covers keeping comparable values within bounds and ranges.
void main() {
  test('raises a value below the minimum to the minimum', () {
    const value = 3;

    final int coerced = value.coerceAtLeast(5);

    expect(coerced, 5);
  });

  test('keeps a value that reaches the minimum', () {
    const value = 7;

    final int coerced = value.coerceAtLeast(5);

    expect(coerced, 7);
  });

  test('lowers a value above the maximum to the maximum', () {
    const value = 2.5;

    final double coerced = value.coerceAtMost(1.5);

    expect(coerced, 1.5);
  });

  test('keeps a value that stays below the maximum', () {
    const value = 'apple';

    final String coerced = value.coerceAtMost('banana');

    expect(coerced, 'apple');
  });

  test('keeps a value inside the range', () {
    const value = Duration(seconds: 5);

    final Duration coerced = value.coerceIn(
      Duration.zero,
      const Duration(seconds: 10),
    );

    expect(coerced, const Duration(seconds: 5));
  });

  test('moves a value below the range to its start', () {
    final value = DateTime.utc(2019);

    final DateTime coerced = value.coerceIn(
      DateTime.utc(2020),
      DateTime.utc(2021),
    );

    expect(coerced, DateTime.utc(2020));
  });

  test('moves a value above the range to its end', () {
    const value = Version(9);

    final Version coerced = value.coerceIn(const Version(1), const Version(4));

    expect(coerced.number, 4);
  });

  test('refuses a range whose minimum exceeds its maximum', () {
    int coerce() => 3.coerceIn(5, 1);

    expect(coerce, throwsArgumentError);
  });

  test('keeps a value inside a closed range', () {
    const value = 5;

    final int coerced = value.coerceInRange(1.rangeTo(10));

    expect(coerced, 5);
  });

  test('moves a value into a closed range', () {
    const value = 'z';

    final String coerced = value.coerceInRange(
      const ClosedRange<String>('a', 'm'),
    );

    expect(coerced, 'm');
  });

  test('refuses to coerce into an empty range', () {
    int coerce() => 5.coerceInRange(const IntRange(3, 1));

    expect(coerce, throwsArgumentError);
  });
}
