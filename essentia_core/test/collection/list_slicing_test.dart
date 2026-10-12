/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/collection/iterable_windowing.dart';
import 'package:essentia_core/src/collection/list_slicing.dart';
import 'package:test/test.dart';

/// Numbers that end in a run of even ones.
const _numbers = <int>[2, 1, 4, 6];

/// Covers Kotlin's `takeLast`, `dropLast`, `takeLastWhile` and
/// `dropLastWhile` for lists.
void main() {
  test('takes the last elements', () {
    final List<int> tail = _numbers.takeLast(2);

    expect(tail, <int>[4, 6]);
  });

  test('takes every element when more are requested than exist', () {
    final List<int> tail = _numbers.takeLast(9);

    expect(tail, _numbers);
  });

  test('refuses a negative count to take', () {
    List<int> take() => _numbers.takeLast(-1);

    expect(take, throwsRangeError);
  });

  test('drops the last elements', () {
    final List<int> head = _numbers.dropLast(3);

    expect(head, <int>[2]);
  });

  test('drops every element when more are dropped than exist', () {
    final List<int> head = _numbers.dropLast(9);

    expect(head, isEmpty);
  });

  test('refuses a negative count to drop', () {
    List<int> drop() => _numbers.dropLast(-1);

    expect(drop, throwsRangeError);
  });

  test('takes the trailing elements that match', () {
    final List<int> tail = _numbers.takeLastWhile((number) => number.isEven);

    expect(tail, <int>[4, 6]);
  });

  test('takes every element when all of them match', () {
    const evens = <int>[2, 4];

    final List<int> tail = evens.takeLastWhile((number) => number.isEven);

    expect(tail, <int>[2, 4]);
  });

  test('drops the trailing elements that match', () {
    final List<int> head = _numbers.dropLastWhile((number) => number.isEven);

    expect(head, <int>[2, 1]);
  });

  test('hands out slices that cannot be modified', () {
    final List<int> head = _numbers.dropLast(1);

    void modify() => head.add(9);

    expect(modify, throwsUnsupportedError);
  });

  test('slices a list typed as an iterable the same way', () {
    const Iterable<int> numbers = _numbers;

    final List<int> tail = numbers.takeLast(2);

    expect(tail, <int>[4, 6]);
  });
}
