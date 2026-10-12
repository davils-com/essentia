/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/collection/iterable_aggregation.dart';
import 'package:test/test.dart';

/// Three words of different lengths.
const _words = <String>['a', 'bb', 'ccc'];

/// Covers Kotlin's `sumOf`, `count`, `indexOfFirst`, `indexOfLast` and
/// `firstNotNullOf`.
void main() {
  test('sums the selected integers', () {
    final int total = _words.sumOfInt((word) => word.length);

    expect(total, 6);
  });

  test('sums the selected integers of an empty source to zero', () {
    const empty = <String>[];

    final int total = empty.sumOfInt((word) => word.length);

    expect(total, 0);
  });

  test('sums the selected doubles', () {
    final double total = _words.sumOfDouble((word) => word.length / 2);

    expect(total, 3);
  });

  test('sums the selected durations', () {
    final Duration total = _words.sumOfDuration(
      (word) => Duration(seconds: word.length),
    );

    expect(total, const Duration(seconds: 6));
  });

  test('counts the elements that match', () {
    final int count = _words.countWhere((word) => word.length.isOdd);

    expect(count, 2);
  });

  test('finds the index of the first match', () {
    final int index = _words.indexOfFirst((word) => word.length > 1);

    expect(index, 1);
  });

  test('reports a missing first match as minus one', () {
    final int index = _words.indexOfFirst((word) => word.isEmpty);

    expect(index, -1);
  });

  test('finds the index of the last match', () {
    final int index = _words.indexOfLast((word) => word.length < 3);

    expect(index, 1);
  });

  test('reports a missing last match as minus one', () {
    final int index = _words.indexOfLast((word) => word.isEmpty);

    expect(index, -1);
  });

  test('returns the first value that is present after transforming', () {
    const texts = <String>['x', '2', '3'];

    final int number = texts.firstNotNullOf(int.tryParse);

    expect(number, 2);
  });

  test('refuses a first value when every transformation is absent', () {
    const texts = <String>['x'];

    int read() => texts.firstNotNullOf(int.tryParse);

    expect(read, throwsStateError);
  });

  test('returns nothing when every transformation is absent', () {
    const texts = <String>['x'];

    final int? number = texts.firstNotNullOfOrNull(int.tryParse);

    expect(number, isNull);
  });
}
