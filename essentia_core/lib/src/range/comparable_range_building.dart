/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/range/closed_range.dart';
import 'package:essentia_core/src/range/open_end_range.dart';
import 'package:meta/meta.dart';

/// Builds closed and open-ended ranges of comparable values.
///
/// For integers, `IntRangeBuilding` is the more specific extension and
/// builds an iterable `IntRange` instead.
extension ComparableRangeBuilding<T extends Comparable<Object>> on T {
  /// The values from this one up to and including [end].
  ///
  /// Returns the range, which is empty when [end] is smaller.
  @useResult
  ClosedRange<T> rangeTo(T end) => ClosedRange<T>(this, end);

  /// The values from this one up to but excluding [end].
  ///
  /// Returns the range, which is empty when [end] is not larger.
  @useResult
  OpenEndRange<T> rangeUntil(T end) => OpenEndRange<T>(this, end);
}
