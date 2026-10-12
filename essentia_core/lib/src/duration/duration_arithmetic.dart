/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/duration/duration_components.dart';
import 'package:meta/meta.dart';

/// Trailing zeros of the digits of a fraction of a second.
final _trailingZeros = RegExp(r'0+$');

/// How many digits a fraction of a second has at microsecond precision.
const _fractionDigits = 6;

/// Kotlin's `Duration` operations Dart lacks: division by a duration,
/// `toComponents` and `toIsoString`.
extension DurationArithmetic on Duration {
  /// How many times [other] fits into this duration.
  ///
  /// Kotlin's `Duration.div(other: Duration)`.
  ///
  /// Returns the ratio of both durations.
  double operator /(Duration other) => inMicroseconds / other.inMicroseconds;

  /// Splits the duration into days, hours, minutes, seconds and
  /// microseconds.
  ///
  /// Kotlin's `Duration.toComponents`, as a record instead of an action.
  /// Every component of a negative duration is negative.
  ///
  /// Returns the components.
  @useResult
  DurationComponents toComponents() => (
    days: inDays,
    hours: inHours.remainder(Duration.hoursPerDay),
    minutes: inMinutes.remainder(Duration.minutesPerHour),
    seconds: inSeconds.remainder(Duration.secondsPerMinute),
    microseconds: inMicroseconds.remainder(Duration.microsecondsPerSecond),
  );

  /// Renders the duration in the ISO 8601 format, such as `PT1H30M`.
  ///
  /// Days are rendered as hours, a negative duration gets a leading `-`,
  /// and zero is `PT0S`. Kotlin's `Duration.toIsoString()`.
  ///
  /// Returns the ISO 8601 text.
  @useResult
  String toIsoString() {
    final Duration length = abs();
    final int hours = length.inHours;
    final int minutes = length.inMinutes.remainder(Duration.minutesPerHour);
    final int seconds = length.inSeconds.remainder(Duration.secondsPerMinute);
    final int fraction = length.inMicroseconds.remainder(
      Duration.microsecondsPerSecond,
    );
    final bool hasSeconds = seconds != 0 || fraction != 0;
    final bool hasMinutes = minutes != 0 || (hasSeconds && hours != 0);
    final bool needsSeconds = hasSeconds || (hours == 0 && !hasMinutes);
    return <String>[
      if (isNegative) '-',
      'PT',
      if (hours != 0) '${hours}H',
      if (hasMinutes) '${minutes}M',
      if (needsSeconds) '$seconds${_fractionOf(fraction)}S',
    ].join();
  }
}

/// Renders [microseconds] as the fraction of a second, without trailing
/// zeros.
///
/// Returns the fraction with its leading `.`, or empty text for zero.
String _fractionOf(int microseconds) {
  if (microseconds == 0) {
    return '';
  }
  final String digits = microseconds
      .toString()
      .padLeft(_fractionDigits, '0')
      .replaceFirst(_trailingZeros, '');
  return '.$digits';
}
