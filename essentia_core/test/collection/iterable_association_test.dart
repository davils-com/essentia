/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/collection/iterable_association.dart';
import 'package:test/test.dart';

/// Three words, two of them sharing an initial.
const _words = <String>['apple', 'avocado', 'banana'];

/// Covers Kotlin's `associate`, `associateWith`, `partition` and
/// `groupingBy`.
void main() {
  test('associates the pairs the transformation builds', () {
    final Map<String, int> lengths = _words.associate(
      (word) => (word, word.length),
    );

    expect(lengths, <String, int>{'apple': 5, 'avocado': 7, 'banana': 6});
  });

  test('keeps the last value of a repeated key', () {
    final Map<String, String> byInitial = _words.associate(
      (word) => (word[0], word),
    );

    expect(byInitial, <String, String>{'a': 'avocado', 'b': 'banana'});
  });

  test('associates every element with its value', () {
    final Map<String, int> lengths = _words.associateWith(
      (word) => word.length,
    );

    expect(lengths.values, <int>[5, 7, 6]);
  });

  test('hands out an association that cannot be modified', () {
    final Map<String, int> lengths = _words.associateWith(
      (word) => word.length,
    );

    void modify() => lengths['cherry'] = 6;

    expect(modify, throwsUnsupportedError);
  });

  test('splits the elements into matched and unmatched ones', () {
    const numbers = <int>[1, 2, 3, 4];

    final ({List<int> matched, List<int> unmatched}) parts = numbers
        .partitionWhere((number) => number.isEven);

    expect((parts.matched, parts.unmatched).toString(), '([2, 4], [1, 3])');
  });

  test('hands out partitions that cannot be modified', () {
    const numbers = <int>[1, 2];
    final List<int> matched = numbers
        .partitionWhere((number) => number.isEven)
        .matched;

    void modify() => matched.add(4);

    expect(modify, throwsUnsupportedError);
  });

  test('groups the elements by a key', () {
    final Map<String, int> counts = _words
        .groupingBy((word) => word[0])
        .eachCount();

    expect(counts, <String, int>{'a': 2, 'b': 1});
  });
}
