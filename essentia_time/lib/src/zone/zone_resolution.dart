/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// How a local time that a shift of the clocks makes ambiguous or skips
/// becomes a moment, when a time zone converts it to an `Instant`.
///
/// A local time in a gap, which the clocks jump over, is moved forward by
/// the length of the gap whatever is chosen, unless [strict]; a local time
/// in an overlap, which the clocks pass twice, takes the offset chosen.
enum ZoneResolution {
  /// The offset in effect before the shift: the first of two passes,
  /// RFC 5545's choice and the default.
  earlierOffset,

  /// The offset in effect after the shift: the second of two passes.
  laterOffset,

  /// Neither: a local time in a gap or an overlap is refused with a
  /// `DateTimeArithmeticException`.
  strict,
}
