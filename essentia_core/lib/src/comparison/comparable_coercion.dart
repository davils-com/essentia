/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/range/closed_range.dart';
import 'package:meta/meta.dart';

/// Keeps a comparable value within bounds, Kotlin's `coerceAtLeast`,
/// `coerceAtMost` and `coerceIn`.
extension ComparableCoercion<T extends Comparable<Object>> on T {
  /// Raises this value to [minimum] when it lies below it, Kotlin's
  /// `coerceAtLeast`.
  ///
  /// Returns this value, or [minimum] when this value is smaller.
  @useResult
  T coerceAtLeast(T minimum) => compareTo(minimum) < 0 ? minimum : this;

  /// Lowers this value to [maximum] when it lies above it, Kotlin's
  /// `coerceAtMost`.
  ///
  /// Returns this value, or [maximum] when this value is larger.
  @useResult
  T coerceAtMost(T maximum) => compareTo(maximum) > 0 ? maximum : this;

  /// Moves this value into the bounds [minimum] and [maximum], both
  /// included, Kotlin's `coerceIn`.
  ///
  /// Returns this value, or the bound it lies beyond.
  ///
  /// Throws an [ArgumentError] if [minimum] exceeds [maximum].
  @useResult
  T coerceIn(T minimum, T maximum) {
    if (minimum.compareTo(maximum) > 0) {
      throw ArgumentError(
        'The range $minimum..$maximum is empty, $minimum exceeds $maximum.',
      );
    }
    return coerceAtLeast(minimum).coerceAtMost(maximum);
  }

  /// Moves this value into [range], Kotlin's `coerceIn` for a
  /// `ClosedRange`.
  ///
  /// Returns this value, or the end of [range] it lies beyond.
  ///
  /// Throws an [ArgumentError] if [range] is empty.
  @useResult
  T coerceInRange(ClosedRange<T> range) {
    if (range.isEmpty) {
      throw ArgumentError.value(range, 'range', 'must not be empty');
    }
    return coerceIn(range.start, range.endInclusive);
  }
}
