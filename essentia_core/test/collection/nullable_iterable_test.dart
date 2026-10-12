/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/collection/nullable_iterable.dart';
import 'package:test/test.dart';

/// Covers Kotlin's `isNullOrEmpty` and `orEmpty` for an absent iterable.
void main() {
  test('treats an absent iterable as empty', () {
    const Iterable<int>? absent = null;

    final bool empty = absent.isNullOrEmpty;

    expect(empty, isTrue);
  });

  test('treats an empty iterable as empty', () {
    const Iterable<int> none = <int>[];

    final bool empty = none.isNullOrEmpty;

    expect(empty, isTrue);
  });

  test('treats an iterable with elements as not empty', () {
    const Iterable<int> some = <int>[1];

    final bool empty = some.isNullOrEmpty;

    expect(empty, isFalse);
  });

  test('replaces an absent iterable with an empty one', () {
    const Iterable<int>? absent = null;

    final Iterable<int> elements = absent.orEmpty();

    expect(elements, isEmpty);
  });

  test('keeps an iterable that is present', () {
    const Iterable<int> some = <int>[1];

    final Iterable<int> elements = some.orEmpty();

    expect(elements, <int>[1]);
  });
}
