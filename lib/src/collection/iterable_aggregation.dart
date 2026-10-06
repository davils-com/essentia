/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Kotlin's aggregate functions: sums, counts, indexes and the first value
/// a transformation produces.
extension IterableAggregation<T> on Iterable<T> {
  /// Adds up the integer [selector] computes for every element.
  ///
  /// Kotlin's `sumOf` for `Int`.
  ///
  /// Returns the sum, zero for no elements.
  @useResult
  int sumOfInt(int Function(T element) selector) =>
      fold(0, (sum, element) => sum + selector(element));

  /// Adds up the double [selector] computes for every element.
  ///
  /// Kotlin's `sumOf` for `Double`.
  ///
  /// Returns the sum, zero for no elements.
  @useResult
  double sumOfDouble(double Function(T element) selector) =>
      fold(0, (sum, element) => sum + selector(element));

  /// Adds up the duration [selector] computes for every element.
  ///
  /// Kotlin's `sumOf` for `Duration`.
  ///
  /// Returns the sum, [Duration.zero] for no elements.
  @useResult
  Duration sumOfDuration(Duration Function(T element) selector) =>
      fold(Duration.zero, (sum, element) => sum + selector(element));

  /// Counts the elements [predicate] accepts.
  ///
  /// Kotlin's `count` with a predicate.
  ///
  /// Returns the number of accepted elements.
  @useResult
  int countWhere(bool Function(T element) predicate) =>
      fold(0, (count, element) => predicate(element) ? count + 1 : count);

  /// Finds the first element [predicate] accepts.
  ///
  /// Kotlin's `indexOfFirst`.
  ///
  /// Returns its index, or `-1` when no element is accepted.
  @useResult
  int indexOfFirst(bool Function(T element) predicate) {
    for (final (int index, T element) in indexed) {
      if (predicate(element)) {
        return index;
      }
    }
    return -1;
  }

  /// Finds the last element [predicate] accepts.
  ///
  /// Kotlin's `indexOfLast`.
  ///
  /// Returns its index, or `-1` when no element is accepted.
  @useResult
  int indexOfLast(bool Function(T element) predicate) {
    var found = -1;
    for (final (int index, T element) in indexed) {
      if (predicate(element)) {
        found = index;
      }
    }
    return found;
  }

  /// Transforms the elements in order until [transform] returns a value.
  ///
  /// Kotlin's `firstNotNullOf`.
  ///
  /// Returns the first value that is not `null`.
  ///
  /// Throws a [StateError] if every element is transformed into `null`.
  @useResult
  R firstNotNullOf<R extends Object>(R? Function(T element) transform) =>
      firstNotNullOfOrNull(transform) ??
      (throw StateError('No element was transformed into a value.'));

  /// Transforms the elements in order until [transform] returns a value.
  ///
  /// Kotlin's `firstNotNullOfOrNull`.
  ///
  /// Returns the first value that is not `null`, or `null` if there is
  /// none.
  @useResult
  R? firstNotNullOfOrNull<R extends Object>(R? Function(T element) transform) =>
      map(transform).nonNulls.firstOrNull;
}
