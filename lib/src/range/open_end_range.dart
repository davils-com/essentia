/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

part 'comparable_open_end_range.dart';

/// A range of comparable values from [start] up to but excluding
/// [endExclusive], Kotlin's `OpenEndRange`.
///
/// The range is empty when [start] reaches [endExclusive].
abstract interface class OpenEndRange<T extends Comparable<Object>> {
  /// Creates the range from [start] up to but excluding [endExclusive].
  ///
  /// Two such ranges are equal when both of their ends are equal, and the
  /// range describes itself as `start..<endExclusive`, like Kotlin's.
  const factory OpenEndRange(T start, T endExclusive) = _ComparableOpenEndRange;

  /// The smallest value of the range.
  T get start;

  /// The first value beyond the range, which the range does not contain.
  T get endExclusive;

  /// Whether the range holds no value, because [start] reaches
  /// [endExclusive].
  bool get isEmpty;

  /// Whether [value] lies between [start], included, and [endExclusive],
  /// excluded.
  ///
  /// Returns `true` for a value of the range.
  bool contains(T value);
}
