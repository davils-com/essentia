/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// How a number that falls between two representable values is rounded.
enum RoundingMode {
  /// Towards positive infinity: 1.1 is 2, -1.9 is -1.
  ceiling,

  /// Towards negative infinity: 1.9 is 1, -1.1 is -2.
  floor,

  /// Towards zero, cutting the digits off: 1.9 is 1, -1.9 is -1.
  down,

  /// Away from zero: 1.1 is 2, -1.1 is -2.
  up,

  /// To the nearest neighbour, a tie to the even one: 2.5 is 2, 3.5 is 4.
  /// What CLDR formats with unless told otherwise.
  halfEven,

  /// To the nearest neighbour, a tie away from zero: 2.5 is 3, -2.5 is -3.
  halfUp,

  /// To the nearest neighbour, a tie towards zero: 2.5 is 2, -2.5 is -2.
  halfDown,
}
