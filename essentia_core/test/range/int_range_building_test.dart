/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/range/int_progression.dart';
import 'package:essentia_core/src/range/int_range_building.dart';
import 'package:test/test.dart';

/// Covers building integer ranges with `rangeTo`, `until` and `downTo`.
void main() {
  test('builds a range up to and including its end', () {
    const start = 1;

    final IntRange range = start.rangeTo(3);

    expect(range.toList(), <int>[1, 2, 3]);
  });

  test('builds a range that stops before its end', () {
    const start = 1;

    final IntRange range = start.until(3);

    expect(range.toList(), <int>[1, 2]);
  });

  test('builds an empty range until its own start', () {
    const start = 3;

    final IntRange range = start.until(3);

    expect(range.isEmpty, isTrue);
  });

  test('builds a progression counting down', () {
    const start = 3;

    final IntProgression progression = start.downTo(1);

    expect(progression.toList(), <int>[3, 2, 1]);
  });
}
