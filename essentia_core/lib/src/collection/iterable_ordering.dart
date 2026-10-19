/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:collection';

import 'package:meta/meta.dart';

/// Orders the elements of an iterable by copying them into a new, ordered
/// collection.
extension IterableOrdering<T> on Iterable<T> {
  /// Sorts the elements by the key [keyOf] computes, largest first; the
  /// sort is stable, so elements with equal keys keep their order.
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
  /// Returns the reversed elements as an unmodifiable list.
  @useResult
  List<T> toReversedList() => List<T>.unmodifiable(toList().reversed);

  /// Copies the distinct elements into a set sorted by [compare], or by
  /// their natural order without one.
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
