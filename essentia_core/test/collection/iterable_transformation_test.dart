/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/collection/iterable_transformation.dart';
import 'package:test/test.dart';

import 'probe_iterable.dart';

/// Covers Kotlin's `mapNotNull`, `distinct`, `onEach`, `zip`, `plus`,
/// `minus` and `ifEmpty` for iterables.
void main() {
  test('maps and keeps only the present results', () {
    const texts = <String>['1', 'x', '3'];

    final List<int> numbers = texts.mapNotNull(int.tryParse).toList();

    expect(numbers, <int>[1, 3]);
  });

  test('maps with the index and keeps only the present results', () {
    const texts = <String>['a', 'b', 'c'];

    final List<String> kept = texts
        .mapIndexedNotNull((index, text) => index.isEven ? '$index$text' : null)
        .toList();

    expect(kept, <String>['0a', '2c']);
  });

  test('keeps the first occurrence of every element', () {
    const numbers = <int>[3, 1, 3, 2, 1];

    final List<int> distinct = numbers.distinct().toList();

    expect(distinct, <int>[3, 1, 2]);
  });

  test('keeps the first element of every key', () {
    const words = <String>['apple', 'avocado', 'banana', 'blueberry'];

    final List<String> distinct = words.distinctBy((word) => word[0]).toList();

    expect(distinct, <String>['apple', 'banana']);
  });

  test('forgets the seen keys when iterated again', () {
    final Iterable<int> distinct = <int>[1, 1].distinct();

    final List<int> second = (distinct..toList()).toList();

    expect(second, <int>[1]);
  });

  test('keeps distinct elements of an endless source lazily', () {
    final List<int> distinct = naturals()
        .map((number) => number ~/ 2)
        .distinct()
        .take(3)
        .toList();

    expect(distinct, <int>[0, 1, 2]);
  });

  test('runs the action for every element it passes on', () {
    final seen = <int>[];

    final List<int> passed = <int>[1, 2].onEach(seen.add).toList();

    expect(seen, passed);
  });

  test('runs no action before the elements are requested', () {
    final seen = <int>[];

    ProbeIterable<int>(<int>[1, 2])
        .iterationsWhileBuilding((source) => source.onEach(seen.add));

    expect(seen, isEmpty);
  });

  test('runs the action with the index of every element', () {
    final seen = <String>[];

    <String>[
      'a',
      'b',
    ].onEachIndexed((index, text) => seen.add('$index$text')).toList();

    expect(seen, <String>['0a', '1b']);
  });

  test('pairs the elements of two iterables up to the shorter one', () {
    const numbers = <int>[1, 2, 3];

    final List<(int, String)> pairs = numbers.zip(<String>['a', 'b']).toList();

    expect(pairs, <(int, String)>[(1, 'a'), (2, 'b')]);
  });

  test('pairs an endless source with a finite one', () {
    final List<(int, String)> pairs = naturals().zip(<String>[
      'a',
      'b',
    ]).toList();

    expect(pairs, <(int, String)>[(0, 'a'), (1, 'b')]);
  });

  test('appends a single element', () {
    const numbers = <int>[1, 2];

    final List<int> extended = numbers.plusElement(3).toList();

    expect(extended, <int>[1, 2, 3]);
  });

  test('removes the first occurrence of an element', () {
    const numbers = <int>[1, 2, 1];

    final List<int> reduced = numbers.minusElement(1).toList();

    expect(reduced, <int>[2, 1]);
  });

  test('keeps every element when the removed one is missing', () {
    const numbers = <int>[1, 2];

    final List<int> reduced = numbers.minusElement(3).toList();

    expect(reduced, <int>[1, 2]);
  });

  test('removes every occurrence of the given elements', () {
    const numbers = <int>[1, 2, 3, 1, 2];

    final List<int> reduced = numbers.minusAll(<int>[1, 2]).toList();

    expect(reduced, <int>[3]);
  });

  test('keeps the elements of a source that is not empty', () {
    const numbers = <int>[1];

    final List<int> kept = numbers.ifEmpty(() => <int>[9]).toList();

    expect(kept, <int>[1]);
  });

  test('falls back when the source is empty', () {
    const numbers = <int>[];

    final List<int> kept = numbers.ifEmpty(() => <int>[9]).toList();

    expect(kept, <int>[9]);
  });

  test('does not iterate before the elements are requested', () {
    final probe = ProbeIterable<int>(<int>[1, 2]);

    final int iterations = probe.iterationsWhileBuilding(
      (source) => source.ifEmpty(() => <int>[]),
    );

    expect(iterations, 0);
  });
}
