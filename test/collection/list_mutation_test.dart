/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/collection/list_mutation.dart';
import 'package:test/test.dart';

/// Covers Kotlin's `removeFirst`, `removeFirstOrNull` and
/// `removeLastOrNull`.
void main() {
  test('removes and returns the first element', () {
    final numbers = <int>[1, 2];

    final int removed = numbers.removeFirst();

    expect((removed, numbers.single), (1, 2));
  });

  test('refuses to remove the first element of an empty list', () {
    final numbers = <int>[];

    int remove() => numbers.removeFirst();

    expect(remove, throwsStateError);
  });

  test('removes the first element or nothing', () {
    final numbers = <int>[];

    final int? removed = numbers.removeFirstOrNull();

    expect(removed, isNull);
  });

  test('removes the first element when one exists', () {
    final numbers = <int>[1, 2];

    final int? removed = numbers.removeFirstOrNull();

    expect(removed, 1);
  });

  test('removes the last element or nothing', () {
    final numbers = <int>[];

    final int? removed = numbers.removeLastOrNull();

    expect(removed, isNull);
  });

  test('removes the last element when one exists', () {
    final numbers = <int>[1, 2];

    final int? removed = numbers.removeLastOrNull();

    expect(removed, 2);
  });
}
