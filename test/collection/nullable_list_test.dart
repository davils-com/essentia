/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/collection/nullable_list.dart';
import 'package:test/test.dart';

/// Covers Kotlin's `orEmpty` for an absent list.
void main() {
  test('replaces an absent list with an empty one', () {
    const List<int>? absent = null;

    final List<int> numbers = absent.orEmpty();

    expect(numbers, isEmpty);
  });

  test('replaces an absent list with one that cannot grow', () {
    const List<int>? absent = null;
    final List<int> numbers = absent.orEmpty();

    void modify() => numbers.add(1);

    expect(modify, throwsUnsupportedError);
  });

  test('keeps a list that is present', () {
    const present = <int>[1];

    final List<int> numbers = present.orEmpty();

    expect(numbers, <int>[1]);
  });
}
