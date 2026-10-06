/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

part 'comparable_closed_range.dart';

/// A range of comparable values from [start] up to and including
/// [endInclusive], Kotlin's `ClosedRange`.
///
/// The range is empty when [start] lies beyond [endInclusive]. `IntRange`
/// is the closed range of integers that can also be iterated.
abstract interface class ClosedRange<T extends Comparable<Object>> {
  /// Creates the range from [start] up to and including [endInclusive].
  ///
  /// Two such ranges are equal when both of their ends are equal, and the
  /// range describes itself as `start..endInclusive`, like Kotlin's.
  const factory ClosedRange(T start, T endInclusive) = _ComparableClosedRange;

  /// The smallest value of the range.
  T get start;

  /// The largest value of the range, which the range contains.
  T get endInclusive;

  /// Whether the range holds no value, because [start] lies beyond
  /// [endInclusive].
  bool get isEmpty;

  /// Whether [value] lies between [start] and [endInclusive], both
  /// included.
  ///
  /// Returns `true` for a value of the range.
  bool contains(T value);
}
