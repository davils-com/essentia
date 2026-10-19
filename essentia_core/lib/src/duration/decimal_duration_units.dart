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

/// Duration units on a decimal number, so that `1.5.seconds` reads as
/// a duration.
///
/// A [Duration] counts whole microseconds, so the result is rounded to the
/// nearest one.
extension DecimalDurationUnits on double {
  /// This many days, rounded to whole microseconds.
  Duration get days => _of(Duration.microsecondsPerDay);

  /// This many hours, rounded to whole microseconds.
  Duration get hours => _of(Duration.microsecondsPerHour);

  /// This many minutes, rounded to whole microseconds.
  Duration get minutes => _of(Duration.microsecondsPerMinute);

  /// This many seconds, rounded to whole microseconds.
  Duration get seconds => _of(Duration.microsecondsPerSecond);

  /// This many milliseconds, rounded to whole microseconds.
  Duration get milliseconds => _of(Duration.microsecondsPerMillisecond);

  /// This many microseconds, rounded to whole ones.
  Duration get microseconds => _of(1);

  /// This many units of [microsecondsPerUnit] microseconds each.
  ///
  /// Returns the duration, rounded to whole microseconds.
  Duration _of(int microsecondsPerUnit) =>
      Duration(microseconds: (this * microsecondsPerUnit).round());
}
