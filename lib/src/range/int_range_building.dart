/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/range/int_progression.dart';
import 'package:meta/meta.dart';

/// Builds integer ranges and progressions the way Kotlin's `..`, `until`
/// and `downTo` do.
extension IntRangeBuilding on int {
  /// The integers from this one up to and including [end], Kotlin's
  /// `rangeTo` and `..`.
  ///
  /// Returns the range, which is empty when [end] is smaller.
  @useResult
  IntRange rangeTo(int end) => IntRange(this, end);

  /// The integers from this one up to but excluding [end], Kotlin's
  /// `until`.
  ///
  /// Returns the range, which is empty when [end] is not larger.
  @useResult
  IntRange until(int end) => IntRange(this, end - 1);

  /// The integers from this one down to and including [end], Kotlin's
  /// `downTo`.
  ///
  /// Returns the progression with a step of minus one, which is empty when
  /// [end] is larger.
  @useResult
  IntProgression downTo(int end) => IntProgression(this, end, step: -1);
}
