/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/collection/comparable_iterable_ordering.dart';
import 'package:test/test.dart';

/// Covers Kotlin's `sortedDescending`.
void main() {
  test('sorts comparable elements descending', () {
    const words = <String>['b', 'c', 'a'];

    final List<String> sorted = words.sortedDescending();

    expect(sorted, <String>['c', 'b', 'a']);
  });

  test('hands out a descending list that cannot be modified', () {
    const numbers = <int>[1];
    final List<int> sorted = numbers.sortedDescending();

    void modify() => sorted.add(2);

    expect(modify, throwsUnsupportedError);
  });
}
