/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/collection/iterable_ordering.dart';
import 'package:test/test.dart';

/// Covers Kotlin's `sortedByDescending`, `reversed` and `toSortedSet`.
void main() {
  test('sorts by a key descending and keeps the order of equal keys', () {
    const words = <String>['bb', 'a', 'cc', 'ddd'];

    final List<String> sorted = words.sortedByDescending((word) => word.length);

    expect(sorted, <String>['ddd', 'bb', 'cc', 'a']);
  });

  test('hands out a sorted list that cannot be modified', () {
    const words = <String>['a'];
    final List<String> sorted = words.sortedByDescending((word) => word.length);

    void modify() => sorted.add('b');

    expect(modify, throwsUnsupportedError);
  });

  test('reverses the elements into a list', () {
    const numbers = <int>[1, 2, 3];

    final List<int> reversed = numbers.toReversedList();

    expect(reversed, <int>[3, 2, 1]);
  });

  test('collects the elements into a naturally sorted set', () {
    const numbers = <int>[3, 1, 3, 2];

    final Set<int> sorted = numbers.toSortedSet();

    expect(sorted.toList(), <int>[1, 2, 3]);
  });

  test('collects the elements into a set sorted by a comparator', () {
    const numbers = <int>[3, 1, 2];

    final Set<int> sorted = numbers.toSortedSet((left, right) => right - left);

    expect(sorted.toList(), <int>[3, 2, 1]);
  });

  test('hands out a sorted set that cannot be modified', () {
    const numbers = <int>[1];
    final Set<int> sorted = numbers.toSortedSet();

    void modify() => sorted.add(2);

    expect(modify, throwsUnsupportedError);
  });
}
