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

import 'package:essentia_core/src/range/closed_range.dart';
import 'package:essentia_core/src/range/comparable_range_building.dart';
import 'package:essentia_core/src/range/int_progression.dart';
import 'package:essentia_core/src/range/int_range_building.dart';
import 'package:essentia_core/src/range/open_end_range.dart';
import 'package:test/test.dart';

/// Covers building ranges of comparable values with `rangeTo` and
/// `rangeUntil`.
void main() {
  test('builds a closed range between two comparable values', () {
    final start = DateTime.utc(2020);

    final ClosedRange<DateTime> range = start.rangeTo(DateTime.utc(2021));

    expect(range.contains(DateTime.utc(2021)), isTrue);
  });

  test('builds a range with an open end', () {
    const start = 'a';

    final OpenEndRange<String> range = start.rangeUntil('c');

    expect(range.contains('c'), isFalse);
  });

  test('prefers the integer range for integers', () {
    const start = 1;

    final Object range = start.rangeTo(2);

    expect(range, isA<IntRange>());
  });
}
