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

import 'package:essentia_core/src/duration/duration_components.dart';
import 'package:meta/meta.dart';

/// Trailing zeros of the digits of a fraction of a second.
final _trailingZeros = RegExp(r'0+$');

/// How many digits a fraction of a second has at microsecond precision.
const _fractionDigits = 6;

/// The [Duration] operations Dart lacks: division by a duration,
/// `toComponents` and `toIsoString`.
extension DurationArithmetic on Duration {
  /// How many times [other] fits into this duration.
  ///
  /// Returns the ratio of both durations.
  double operator /(Duration other) => inMicroseconds / other.inMicroseconds;

  /// Splits the duration into days, hours, minutes, seconds and
  /// microseconds.
  ///
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
  /// and zero is `PT0S`.
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
