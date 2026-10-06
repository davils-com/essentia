/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Kotlin's `Int.days`, `Int.hours` and the other duration units, so that
/// `5.seconds` reads like it does in Kotlin.
extension DurationUnits on int {
  /// This many days.
  ///
  /// Kotlin's `Int.days`.
  Duration get days => Duration(days: this);

  /// This many hours.
  ///
  /// Kotlin's `Int.hours`.
  Duration get hours => Duration(hours: this);

  /// This many minutes.
  ///
  /// Kotlin's `Int.minutes`.
  Duration get minutes => Duration(minutes: this);

  /// This many seconds.
  ///
  /// Kotlin's `Int.seconds`.
  Duration get seconds => Duration(seconds: this);

  /// This many milliseconds.
  ///
  /// Kotlin's `Int.milliseconds`.
  Duration get milliseconds => Duration(milliseconds: this);

  /// This many microseconds.
  ///
  /// Kotlin's `Int.microseconds`.
  Duration get microseconds => Duration(microseconds: this);
}
