/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// A duration split into whole days, hours, minutes and seconds and the
/// microseconds of the last second.
///
/// What `Duration.toComponents` returns. Every component carries the sign
/// of the duration.
typedef DurationComponents = ({
  int days,
  int hours,
  int minutes,
  int seconds,
  int microseconds,
});
