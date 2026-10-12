/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/range/open_end_range.dart';
import 'package:test/test.dart';

/// Covers the range of comparable values with an open end.
void main() {
  test('contains its start', () {
    const range = OpenEndRange<num>(1, 3);

    final bool contained = range.contains(1);

    expect(contained, isTrue);
  });

  test('excludes its end', () {
    const range = OpenEndRange<num>(1, 3);

    final bool contained = range.contains(3);

    expect(contained, isFalse);
  });

  test('excludes a value before its start', () {
    const range = OpenEndRange<num>(1, 3);

    final bool contained = range.contains(0);

    expect(contained, isFalse);
  });

  test('is empty when its start reaches its end', () {
    const range = OpenEndRange<num>(2, 2);

    final bool empty = range.isEmpty;

    expect(empty, isTrue);
  });

  test('is not empty when its end lies beyond its start', () {
    const range = OpenEndRange<num>(2, 3);

    final bool empty = range.isEmpty;

    expect(empty, isFalse);
  });

  test('equals a range with the same ends', () {
    const range = OpenEndRange<num>(1, 3);

    final equal = range == const OpenEndRange<num>(1, 3);

    expect(equal, isTrue);
  });

  test('differs from a range with another end', () {
    const range = OpenEndRange<num>(1, 3);

    final equal = range == const OpenEndRange<num>(1, 4);

    expect(equal, isFalse);
  });

  test('shares the hash code of an equal range', () {
    const range = OpenEndRange<num>(1, 3);

    final hash = range.hashCode;

    expect(hash, const OpenEndRange<num>(1, 3).hashCode);
  });

  test('describes itself with an open end', () {
    const range = OpenEndRange<num>(1, 3);

    final description = range.toString();

    expect(description, '1..<3');
  });
}
