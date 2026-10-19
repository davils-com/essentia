/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Why a pattern is refused by `LinearRegExp`.
enum LinearRegExpFailure {
  /// The pattern is no regular expression of ECMAScript in its unicode
  /// mode.
  syntax,

  /// The pattern uses what cannot be matched in linear time: a
  /// backreference, a lookahead or a lookbehind.
  unsupported,

  /// The pattern compiles to more instructions than allowed, as a large
  /// count of repetitions does.
  tooComplex,
}
