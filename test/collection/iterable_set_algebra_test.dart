/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/collection/iterable_set_algebra.dart';
import 'package:test/test.dart';

/// Numbers with a repeated element, out of order.
const _numbers = <int>[3, 1, 2, 1];

/// Covers Kotlin's `intersect`, `union`, `subtract` and `containsAll`.
void main() {
  test('keeps the distinct elements both sources share', () {
    final Set<int> shared = _numbers.intersect(<int>[1, 3, 5]);

    expect(shared, <int>{3, 1});
  });

  test('joins the distinct elements of both sources in order', () {
    final Set<int> joined = _numbers.union(<int>[5, 1]);

    expect(joined.toList(), <int>[3, 1, 2, 5]);
  });

  test('removes the elements of the other source', () {
    final Set<int> remaining = _numbers.subtract(<int>[1]);

    expect(remaining, <int>{3, 2});
  });

  test('hands out a set that cannot be modified', () {
    final Set<int> joined = _numbers.union(<int>[5]);

    void modify() => joined.add(7);

    expect(modify, throwsUnsupportedError);
  });

  test('contains every given element', () {
    final bool contained = _numbers.containsAll(<int>[1, 2]);

    expect(contained, isTrue);
  });

  test('misses one of the given elements', () {
    final bool contained = _numbers.containsAll(<int>[1, 4]);

    expect(contained, isFalse);
  });
}
