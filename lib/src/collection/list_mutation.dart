/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Kotlin's removals at either end of a mutable list.
extension ListMutation<T> on List<T> {
  /// Removes the first element of this list.
  ///
  /// Kotlin's `removeFirst`.
  ///
  /// Returns the removed element.
  ///
  /// Throws a [StateError] if the list is empty.
  T removeFirst() {
    if (isEmpty) {
      throw StateError('No element');
    }
    return removeAt(0);
  }

  /// Removes the first element of this list, if there is one.
  ///
  /// Kotlin's `removeFirstOrNull`.
  ///
  /// Returns the removed element, or `null` if the list is empty.
  T? removeFirstOrNull() => isEmpty ? null : removeAt(0);

  /// Removes the last element of this list, if there is one.
  ///
  /// Kotlin's `removeLastOrNull`.
  ///
  /// Returns the removed element, or `null` if the list is empty.
  T? removeLastOrNull() => isEmpty ? null : removeLast();
}
