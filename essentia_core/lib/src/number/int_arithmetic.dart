/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:meta/meta.dart';

/// Floored integer division, `floorDiv` and `mod`.
///
/// Dart's `~/` truncates towards zero and its `%` is never negative; these
/// round towards negative infinity and take the sign of the divisor.
extension IntArithmetic on int {
  /// Divides this integer by [divisor] and rounds the quotient towards
  /// negative infinity.
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

  /// The remainder of the floored division by [divisor].
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
