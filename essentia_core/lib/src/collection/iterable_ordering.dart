/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:collection';

import 'package:meta/meta.dart';

/// Kotlin's ordering functions that copy the elements into a new, ordered
/// collection.
extension IterableOrdering<T> on Iterable<T> {
  /// Sorts the elements by the key [keyOf] computes, largest first; the
  /// sort is stable, so elements with equal keys keep their order.
  ///
  /// Kotlin's `sortedByDescending`.
  ///
  /// Returns the sorted elements as an unmodifiable list.
  @useResult
  List<T> sortedByDescending<K extends Comparable<Object>>(
    K Function(T element) keyOf,
  ) {
    final keyed = <(int, K, T)>[
      for (final (int index, T element) in indexed)
        (index, keyOf(element), element),
    ]..sort(_descendingStably);
    return List<T>.unmodifiable(keyed.map((entry) => entry.$3));
  }

  /// Copies the elements into a list in reverse order.
  ///
  /// Kotlin's `reversed`.
  ///
  /// Returns the reversed elements as an unmodifiable list.
  @useResult
  List<T> toReversedList() => List<T>.unmodifiable(toList().reversed);

  /// Copies the distinct elements into a set sorted by [compare], or by
  /// their natural order without one.
  ///
  /// Kotlin's `toSortedSet`.
  ///
  /// Returns an unmodifiable sorted set.
  @useResult
  Set<T> toSortedSet([Comparator<T>? compare]) =>
      UnmodifiableSetView<T>(SplayTreeSet<T>.of(this, compare));

  /// Orders [left] before [right] when its key is larger, and by the
  /// original position when both keys are equal.
  ///
  /// Returns a negative number, zero or a positive number like any
  /// comparator.
  static int _descendingStably<K extends Comparable<Object>, T>(
    (int, K, T) left,
    (int, K, T) right,
  ) {
    final int byKey = right.$2.compareTo(left.$2);
    if (byKey != 0) {
      return byKey;
    }
    return left.$1.compareTo(right.$1);
  }
}
