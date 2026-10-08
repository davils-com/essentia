/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Kotlin's `ByteArray.contentEquals` and `contentHashCode` on any list of
/// bytes.
extension ByteListContent on List<int> {
  /// Whether [other] holds the same elements in the same order.
  ///
  /// It stops at the first difference, so the time it takes tells how long
  /// the common prefix is: never compare secrets with it. Kotlin's
  /// `ByteArray.contentEquals`.
  ///
  /// Returns `true` when both lists are equal element by element, `false`
  /// when they differ or [other] is `null`.
  @useResult
  bool contentEquals(List<int>? other) {
    if (other == null || other.length != length) {
      return false;
    }
    for (var index = 0; index < length; index++) {
      if (this[index] != other[index]) {
        return false;
      }
    }
    return true;
  }

  /// A hash code of the elements, equal for lists that are
  /// [contentEquals].
  ///
  /// Kotlin's `ByteArray.contentHashCode`.
  ///
  /// Returns the hash code.
  @useResult
  int contentHashCode() => Object.hashAll(this);
}
