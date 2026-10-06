/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

import 'package:meta/meta.dart';

/// Kotlin's `random` and `randomOrNull` for any iterable.
///
/// A list is sampled by index; any other iterable is read once, picking
/// each element with equal probability by reservoir sampling.
extension IterableSampling<T> on Iterable<T> {
  /// Picks an element at random, drawing from [source] or from a fresh
  /// [Random] without one.
  ///
  /// Kotlin's `random`.
  ///
  /// Returns the picked element.
  ///
  /// Throws a [StateError] if there are no elements.
  @useResult
  T random([Random? source]) =>
      (_pick(source ?? Random()) ??
              (throw StateError('Cannot pick from an empty iterable.')))
          .value;

  /// Picks an element at random, drawing from [source] or from a fresh
  /// [Random] without one.
  ///
  /// Kotlin's `randomOrNull`.
  ///
  /// Returns the picked element, or `null` if there are no elements.
  @useResult
  T? randomOrNull([Random? source]) => _pick(source ?? Random())?.value;

  /// Picks an element with [source], wrapped so that a picked `null`
  /// element differs from no element at all.
  ///
  /// Returns the picked element, or `null` if there are no elements.
  ({T value})? _pick(Random source) {
    final elements = this;
    if (elements is List<T>) {
      return elements.isEmpty
          ? null
          : (value: elements[source.nextInt(elements.length)]);
    }
    ({T value})? picked;
    var seen = 0;
    for (final element in elements) {
      if (source.nextInt(++seen) == 0) {
        picked = (value: element);
      }
    }
    return picked;
  }
}
