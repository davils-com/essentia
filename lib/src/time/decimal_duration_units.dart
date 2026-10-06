/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Kotlin's `Double.days`, `Double.hours` and the other duration units, so
/// that `1.5.seconds` reads like it does in Kotlin.
///
/// A [Duration] counts whole microseconds, so the result is rounded to the
/// nearest one.
extension DecimalDurationUnits on double {
  /// This many days, rounded to whole microseconds.
  ///
  /// Kotlin's `Double.days`.
  Duration get days => _of(Duration.microsecondsPerDay);

  /// This many hours, rounded to whole microseconds.
  ///
  /// Kotlin's `Double.hours`.
  Duration get hours => _of(Duration.microsecondsPerHour);

  /// This many minutes, rounded to whole microseconds.
  ///
  /// Kotlin's `Double.minutes`.
  Duration get minutes => _of(Duration.microsecondsPerMinute);

  /// This many seconds, rounded to whole microseconds.
  ///
  /// Kotlin's `Double.seconds`.
  Duration get seconds => _of(Duration.microsecondsPerSecond);

  /// This many milliseconds, rounded to whole microseconds.
  ///
  /// Kotlin's `Double.milliseconds`.
  Duration get milliseconds => _of(Duration.microsecondsPerMillisecond);

  /// This many microseconds, rounded to whole ones.
  ///
  /// Kotlin's `Double.microseconds`.
  Duration get microseconds => _of(1);

  /// This many units of [microsecondsPerUnit] microseconds each.
  ///
  /// Returns the duration, rounded to whole microseconds.
  Duration _of(int microsecondsPerUnit) =>
      Duration(microseconds: (this * microsecondsPerUnit).round());
}
