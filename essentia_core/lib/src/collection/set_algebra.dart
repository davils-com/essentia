/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Kotlin's `plus` and `minus` for a set, which leave the set unchanged
/// and return a new one.
extension SetAlgebra<T> on Set<T> {
  /// Adds [element] to a copy of this set.
  ///
  /// Kotlin's `plus` with a single element.
  ///
  /// Returns the extended set, unmodifiable.
  @useResult
  Set<T> plusElement(T element) => Set<T>.unmodifiable({...this, element});

  /// Removes [element] from a copy of this set.
  ///
  /// Kotlin's `minus` with a single element.
  ///
  /// Returns the reduced set, unmodifiable.
  @useResult
  Set<T> minusElement(T element) =>
      Set<T>.unmodifiable(toSet()..remove(element));

  /// Removes every one of [elements] from a copy of this set.
  ///
  /// Kotlin's `minus` with a collection of elements.
  ///
  /// Returns the reduced set, unmodifiable.
  @useResult
  Set<T> minusAll(Iterable<T> elements) =>
      Set<T>.unmodifiable(difference(elements.toSet()));
}
