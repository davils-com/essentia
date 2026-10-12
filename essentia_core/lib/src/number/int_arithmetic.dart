/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Floored integer division, Kotlin's `floorDiv` and `mod`.
///
/// Dart's `~/` truncates towards zero and its `%` is never negative; these
/// round towards negative infinity and take the sign of the divisor, as
/// Kotlin's do.
extension IntArithmetic on int {
  /// Divides this integer by [divisor] and rounds the quotient towards
  /// negative infinity, Kotlin's `floorDiv`.
  ///
  /// Returns the floored quotient.
  ///
  /// Throws an [UnsupportedError] if [divisor] is zero.
  @useResult
  int floorDiv(int divisor) {
    final int quotient = this ~/ divisor;
    final bool roundedUp =
        (this < 0) != (divisor < 0) && quotient * divisor != this;
    return roundedUp ? quotient - 1 : quotient;
  }

  /// The remainder of the floored division by [divisor], Kotlin's `mod`.
  ///
  /// Returns the remainder, which has the sign of [divisor] or is zero.
  ///
  /// Throws an [UnsupportedError] if [divisor] is zero.
  @useResult
  int mod(int divisor) {
    final int rest = this - this ~/ divisor * divisor;
    final bool signDiffers = rest != 0 && (rest < 0) != (divisor < 0);
    return signDiffers ? rest + divisor : rest;
  }
}
