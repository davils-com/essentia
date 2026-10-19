/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Duration units on an integer, so that `5.seconds` reads as a duration.
extension DurationUnits on int {
  /// This many days.
  Duration get days => Duration(days: this);

  /// This many hours.
  Duration get hours => Duration(hours: this);

  /// This many minutes.
  Duration get minutes => Duration(minutes: this);

  /// This many seconds.
  Duration get seconds => Duration(seconds: this);

  /// This many milliseconds.
  Duration get milliseconds => Duration(milliseconds: this);

  /// This many microseconds.
  Duration get microseconds => Duration(microseconds: this);
}
