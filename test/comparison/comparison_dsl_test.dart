/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/comparison/comparison_dsl.dart';
import 'package:test/test.dart';

/// Covers the comparator factories `compareBy`, `naturalOrder`,
/// `nullsFirst` and their siblings.
void main() {
  test('orders by the key ascending', () {
    final words = <String>['ccc', 'a', 'bb'];

    final sorted = List<String>.of(words)
      ..sort(compareBy((word) => word.length));

    expect(sorted, <String>['a', 'bb', 'ccc']);
  });

  test('orders by the key descending', () {
    final words = <String>['a', 'ccc', 'bb'];

    final sorted = List<String>.of(words)
      ..sort(compareByDescending((word) => word.length));

    expect(sorted, <String>['ccc', 'bb', 'a']);
  });

  test('orders by the natural order', () {
    final numbers = <int>[3, 1, 2];

    final sorted = List<int>.of(numbers)..sort(naturalOrder());

    expect(sorted, <int>[1, 2, 3]);
  });

  test('orders by the reverse of the natural order', () {
    final numbers = <int>[1, 3, 2];

    final sorted = List<int>.of(numbers)..sort(reverseOrder());

    expect(sorted, <int>[3, 2, 1]);
  });

  test('puts absent values first', () {
    final numbers = <int?>[2, null, 1, null];

    final sorted = List<int?>.of(numbers)
      ..sort(nullsFirst(naturalOrder<int>()));

    expect(sorted, <int?>[null, null, 1, 2]);
  });

  test('puts absent values last', () {
    final numbers = <int?>[null, 2, null, 1];

    final sorted = List<int?>.of(numbers)..sort(nullsLast(naturalOrder<int>()));

    expect(sorted, <int?>[1, 2, null, null]);
  });

  test('considers two absent values equal when nulls come first', () {
    final Comparator<int?> comparator = nullsFirst(naturalOrder<int>());

    final int order = comparator(null, null);

    expect(order, 0);
  });

  test('considers two absent values equal when nulls come last', () {
    final Comparator<int?> comparator = nullsLast(naturalOrder<int>());

    final int order = comparator(null, null);

    expect(order, 0);
  });

  test('orders a present value before an absent one when nulls come last', () {
    final Comparator<int?> comparator = nullsLast(naturalOrder<int>());

    final int order = comparator(1, null);

    expect(order, isNegative);
  });

  test('orders a present value after an absent one when nulls come first', () {
    final Comparator<int?> comparator = nullsFirst(naturalOrder<int>());

    final int order = comparator(1, null);

    expect(order, isPositive);
  });

  test('compares an absent value below a present one', () {
    const int? absent = null;

    final int order = compareValues(absent, 1);

    expect(order, isNegative);
  });

  test('compares present values by their natural order', () {
    const later = 'b';

    final int order = compareValues(later, 'a');

    expect(order, isPositive);
  });
}
