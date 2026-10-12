/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Kotlin's set operations for any iterable, which treat the elements as a
/// set and keep the order they first appear in.
extension IterableSetAlgebra<T> on Iterable<T> {
  /// Keeps the distinct elements that [other] contains as well.
  ///
  /// Kotlin's `intersect`.
  ///
  /// Returns the shared elements as an unmodifiable set.
  @useResult
  Set<T> intersect(Iterable<T> other) =>
      Set<T>.unmodifiable(toSet()..retainAll(other));

  /// Joins the distinct elements of this iterable and of [other].
  ///
  /// Kotlin's `union`.
  ///
  /// Returns the joined elements as an unmodifiable set, those of this
  /// iterable first.
  @useResult
  Set<T> union(Iterable<T> other) =>
      Set<T>.unmodifiable(toSet()..addAll(other));

  /// Keeps the distinct elements that [other] does not contain.
  ///
  /// Kotlin's `subtract`.
  ///
  /// Returns the remaining elements as an unmodifiable set.
  @useResult
  Set<T> subtract(Iterable<T> other) =>
      Set<T>.unmodifiable(toSet()..removeAll(other));

  /// Checks whether every one of [elements] is among these elements.
  ///
  /// Kotlin's `containsAll`.
  ///
  /// Returns `true` if none of [elements] is missing.
  @useResult
  bool containsAll(Iterable<T> elements) {
    final Set<T> own = toSet();
    return elements.every(own.contains);
  }
}
