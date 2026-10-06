/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/collection/iterable_extremes.dart';
import 'package:test/test.dart';

/// Words whose lengths tie, so that the first of equal ones has to win.
const _words = <String>['bb', 'a', 'cc', 'd'];

/// A source without elements.
const _empty = <String>[];

/// Orders [left] and [right] by their length.
///
/// Returns a negative number when [left] is shorter.
int _byLength(String left, String right) => left.length - right.length;

/// Covers Kotlin's `maxBy`, `minBy`, `maxOf`, `minOf`, `maxWith` and
/// `minWith` with their `OrNull` variants.
void main() {
  test('finds the first element with the largest key', () {
    final String longest = _words.maxBy((word) => word.length);

    expect(longest, 'bb');
  });

  test('refuses the largest key of an empty source', () {
    String read() => _empty.maxBy((word) => word.length);

    expect(read, throwsStateError);
  });

  test('finds the largest key or nothing', () {
    final String? longest = _empty.maxByOrNull((word) => word.length);

    expect(longest, isNull);
  });

  test('finds the element with the largest key or the element', () {
    final String? longest = _words.maxByOrNull((word) => word.length);

    expect(longest, 'bb');
  });

  test('finds the first element with the smallest key', () {
    final String shortest = _words.minBy((word) => word.length);

    expect(shortest, 'a');
  });

  test('finds the smallest key or nothing', () {
    final String? shortest = _empty.minByOrNull((word) => word.length);

    expect(shortest, isNull);
  });

  test('finds the element with the smallest key or the element', () {
    final String? shortest = _words.minByOrNull((word) => word.length);

    expect(shortest, 'a');
  });

  test('returns the largest selected value', () {
    final int length = _words.maxOf((word) => word.length);

    expect(length, 2);
  });

  test('returns the largest selected value or nothing', () {
    final int? length = _empty.maxOfOrNull((word) => word.length);

    expect(length, isNull);
  });

  test('returns the largest selected value when present', () {
    final int? length = _words.maxOfOrNull((word) => word.length);

    expect(length, 2);
  });

  test('returns the smallest selected value', () {
    final int length = _words.minOf((word) => word.length);

    expect(length, 1);
  });

  test('returns the smallest selected value or nothing', () {
    final int? length = _empty.minOfOrNull((word) => word.length);

    expect(length, isNull);
  });

  test('returns the smallest selected value when present', () {
    final int? length = _words.minOfOrNull((word) => word.length);

    expect(length, 1);
  });

  test('finds the largest element by a comparator', () {
    final String longest = _words.maxWith(_byLength);

    expect(longest, 'bb');
  });

  test('finds the largest element by a comparator or nothing', () {
    final String? longest = _empty.maxWithOrNull(_byLength);

    expect(longest, isNull);
  });

  test('finds the smallest element by a comparator', () {
    final String shortest = _words.minWith(_byLength);

    expect(shortest, 'a');
  });

  test('finds the smallest element by a comparator or nothing', () {
    final String? shortest = _empty.minWithOrNull(_byLength);

    expect(shortest, isNull);
  });

  test('refuses the smallest element of an empty source', () {
    String read() => _empty.minWith(_byLength);

    expect(read, throwsStateError);
  });

  test('keeps an absent element as the largest one', () {
    const values = <int?>[null];

    final int? largest = values.maxWith((left, right) => 0);

    expect(largest, isNull);
  });
}
