/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/range/closed_range.dart';
import 'package:essentia/src/range/comparable_range_building.dart';
import 'package:essentia/src/range/int_progression.dart';
import 'package:essentia/src/range/int_range_building.dart';
import 'package:essentia/src/range/open_end_range.dart';
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
