/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/collection/iterable_accumulation.dart';
import 'package:test/test.dart';

import 'probe_iterable.dart';

/// Covers Kotlin's running folds and reductions and `reduceOrNull`.
void main() {
  test('folds step by step starting with the initial value', () {
    const numbers = <int>[1, 2, 3];

    final List<int> sums = numbers
        .runningFold(10, (sum, number) => sum + number)
        .toList();

    expect(sums, <int>[10, 11, 13, 16]);
  });

  test('yields only the initial value for an empty source', () {
    const numbers = <int>[];

    final List<int> sums = numbers
        .runningFold(10, (sum, number) => sum + number)
        .toList();

    expect(sums, <int>[10]);
  });

  test('folds step by step with the index of every element', () {
    const words = <String>['a', 'b'];

    final List<String> steps = words
        .runningFoldIndexed('', (index, text, word) => '$text$index$word')
        .toList();

    expect(steps, <String>['', '0a', '0a1b']);
  });

  test('folds an endless source lazily', () {
    final List<int> sums = naturals()
        .runningFold(0, (sum, number) => sum + number)
        .take(4)
        .toList();

    expect(sums, <int>[0, 0, 1, 3]);
  });

  test('reduces step by step starting with the first element', () {
    const numbers = <int>[1, 2, 3];

    final List<int> sums = numbers
        .runningReduce((sum, number) => sum + number)
        .toList();

    expect(sums, <int>[1, 3, 6]);
  });

  test('yields nothing when reducing an empty source', () {
    const numbers = <int>[];

    final List<int> sums = numbers
        .runningReduce((sum, number) => sum + number)
        .toList();

    expect(sums, isEmpty);
  });

  test('reduces step by step with the index of every element', () {
    const words = <String>['a', 'b', 'c'];

    final List<String> steps = words
        .runningReduceIndexed((index, text, word) => '$text$index$word')
        .toList();

    expect(steps, <String>['a', 'a1b', 'a1b2c']);
  });

  test('does not iterate before the running values are requested', () {
    final probe = ProbeIterable<int>(<int>[1, 2]);

    final int iterations = probe.iterationsWhileBuilding(
      (source) => source.runningReduce((sum, number) => sum + number),
    );

    expect(iterations, 0);
  });

  test('reduces to the combined value', () {
    const numbers = <int>[1, 2, 3];

    final int? product = numbers.reduceOrNull((left, right) => left * right);

    expect(product, 6);
  });

  test('reduces an empty source to nothing', () {
    const numbers = <int>[];

    final int? product = numbers.reduceOrNull((left, right) => left * right);

    expect(product, isNull);
  });

  test('reduces with the index of every element', () {
    const numbers = <int>[5, 5, 5];

    final int? weighted = numbers.reduceIndexedOrNull(
      (index, sum, number) => sum + index * number,
    );

    expect(weighted, 20);
  });

  test('reduces an empty source with indexes to nothing', () {
    const numbers = <int>[];

    final int? weighted = numbers.reduceIndexedOrNull(
      (index, sum, number) => sum + index * number,
    );

    expect(weighted, isNull);
  });
}
