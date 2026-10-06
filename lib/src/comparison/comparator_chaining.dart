/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/comparison/comparison_dsl.dart';
import 'package:meta/meta.dart';

/// Breaks the ties of a comparator with further keys or comparators,
/// Kotlin's `thenBy`, `thenByDescending` and `thenDescending`.
extension ComparatorChaining<T> on Comparator<T> {
  /// Orders the elements this comparator considers equal by the key
  /// [keyOf] selects, ascending, Kotlin's `thenBy`.
  ///
  /// Returns the chained comparator.
  @useResult
  Comparator<T> thenBy<K extends Comparable<Object>>(
    K Function(T element) keyOf,
  ) => _then(compareBy(keyOf));

  /// Orders the elements this comparator considers equal by the key
  /// [keyOf] selects, descending, Kotlin's `thenByDescending`.
  ///
  /// Returns the chained comparator.
  @useResult
  Comparator<T> thenByDescending<K extends Comparable<Object>>(
    K Function(T element) keyOf,
  ) => _then(compareByDescending(keyOf));

  /// Orders the elements this comparator considers equal by the reverse
  /// of [tieBreaker], Kotlin's `thenDescending`.
  ///
  /// Returns the chained comparator.
  @useResult
  Comparator<T> thenDescending(Comparator<T> tieBreaker) =>
      _then((left, right) => tieBreaker(right, left));

  /// Orders by this comparator first and by [tieBreaker] where this
  /// comparator finds a tie.
  ///
  /// Returns the chained comparator.
  Comparator<T> _then(Comparator<T> tieBreaker) => (left, right) {
    final int order = this(left, right);
    return order == 0 ? tieBreaker(left, right) : order;
  };
}
