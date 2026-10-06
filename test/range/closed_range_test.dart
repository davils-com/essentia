/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/range/closed_range.dart';
import 'package:test/test.dart';

/// Covers the closed range of comparable values.
void main() {
  test('contains both of its ends', () {
    const range = ClosedRange<String>('b', 'd');

    final bool contained = range.contains('b') && range.contains('d');

    expect(contained, isTrue);
  });

  test('excludes a value beyond its end', () {
    const range = ClosedRange<String>('b', 'd');

    final bool contained = range.contains('e');

    expect(contained, isFalse);
  });

  test('excludes a value before its start', () {
    const range = ClosedRange<String>('b', 'd');

    final bool contained = range.contains('a');

    expect(contained, isFalse);
  });

  test('is empty when its start exceeds its end', () {
    const range = ClosedRange<num>(3, 1);

    final bool empty = range.isEmpty;

    expect(empty, isTrue);
  });

  test('is not empty when it holds a single value', () {
    const range = ClosedRange<num>(1, 1);

    final bool empty = range.isEmpty;

    expect(empty, isFalse);
  });

  test('equals a range with the same ends', () {
    const range = ClosedRange<num>(1, 3);

    final equal = range == const ClosedRange<num>(1, 3);

    expect(equal, isTrue);
  });

  test('differs from a range with another end', () {
    const range = ClosedRange<num>(1, 3);

    final equal = range == const ClosedRange<num>(1, 4);

    expect(equal, isFalse);
  });

  test('shares the hash code of an equal range', () {
    const range = ClosedRange<num>(1, 3);

    final hash = range.hashCode;

    expect(hash, const ClosedRange<num>(1, 3).hashCode);
  });

  test('describes itself with both ends', () {
    const range = ClosedRange<num>(1, 3);

    final description = range.toString();

    expect(description, '1..3');
  });
}
