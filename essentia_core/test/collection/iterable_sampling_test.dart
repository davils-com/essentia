/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

import 'package:essentia_core/src/collection/iterable_sampling.dart';
import 'package:test/test.dart';

import 'probe_iterable.dart';

/// The seed of every random source, so that a run can be repeated.
const _seed = 11;

/// Covers Kotlin's `random` and `randomOrNull`.
void main() {
  test('picks a random element of a list', () {
    const numbers = <int>[4, 5, 6];

    final int picked = numbers.random(Random(_seed));

    expect(numbers, contains(picked));
  });

  test('picks a random element of a lazy source in one pass', () {
    final probe = ProbeIterable<int>(<int>[4, 5, 6]);

    final int picked = probe.random(Random(_seed));

    expect((probe.contains(picked), probe.iterations), (true, 2));
  });

  test('picks without a given random source', () {
    const numbers = <int>[4];

    final int picked = numbers.random();

    expect(picked, 4);
  });

  test('refuses to pick from an empty list', () {
    const empty = <int>[];

    int pick() => empty.random();

    expect(pick, throwsStateError);
  });

  test('picks nothing from an empty lazy source', () {
    final Iterable<int> empty = const <int>[].where((number) => number > 0);

    final int? picked = empty.randomOrNull();

    expect(picked, isNull);
  });

  test('picks nothing from an empty list', () {
    const empty = <int>[];

    final int? picked = empty.randomOrNull(Random(_seed));

    expect(picked, isNull);
  });
}
