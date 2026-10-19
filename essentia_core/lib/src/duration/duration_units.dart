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
