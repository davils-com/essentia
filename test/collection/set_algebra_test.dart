/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/collection/set_algebra.dart';
import 'package:test/test.dart';

/// The numbers from one to three.
const _numbers = <int>{1, 2, 3};

/// Covers Kotlin's `plus` and `minus` for sets.
void main() {
  test('adds an element into a new set', () {
    final Set<int> extended = _numbers.plusElement(4);

    expect(extended, <int>{1, 2, 3, 4});
  });

  test('removes an element into a new set', () {
    final Set<int> reduced = _numbers.minusElement(2);

    expect(reduced, <int>{1, 3});
  });

  test('removes several elements into a new set', () {
    final Set<int> reduced = _numbers.minusAll(<int>[1, 3, 5]);

    expect(reduced, <int>{2});
  });

  test('hands out a set that cannot be modified', () {
    final Set<int> extended = _numbers.plusElement(4);

    void modify() => extended.add(5);

    expect(modify, throwsUnsupportedError);
  });
}
