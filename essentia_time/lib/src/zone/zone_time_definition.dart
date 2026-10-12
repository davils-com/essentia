/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// What clock the time of a `ZoneTransitionRule` is read on.
enum ZoneTimeDefinition {
  /// The wall clock, with the offset in effect before the shift.
  wall,

  /// The clock of standard time, without daylight saving.
  standard,

  /// UTC.
  utc,
}
