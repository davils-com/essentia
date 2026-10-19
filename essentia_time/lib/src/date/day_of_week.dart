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

/// A day of the week.
///
/// The days run from [monday] to [sunday], as ISO 8601 orders them, and
/// [isoDayNumber] numbers them from 1 to 7.
enum DayOfWeek {
  /// Monday, the first day of an ISO week.
  monday,

  /// Tuesday.
  tuesday,

  /// Wednesday.
  wednesday,

  /// Thursday.
  thursday,

  /// Friday.
  friday,

  /// Saturday.
  saturday,

  /// Sunday, the last day of an ISO week.
  sunday;

  /// The day of [isoDayNumber], from 1 for Monday to 7 for Sunday.
  ///
  /// Throws an [ArgumentError] for any other number.
  static DayOfWeek of(int isoDayNumber) {
    if (isoDayNumber < 1 || isoDayNumber > 7) {
      throw ArgumentError.value(
        isoDayNumber,
        'isoDayNumber',
        'Must be from 1 to 7',
      );
    }
    return values[isoDayNumber - 1];
  }

  /// The number of the day as ISO 8601 counts: 1 for Monday to 7 for
  /// Sunday, which is also what `DateTime.weekday` reads.
  int get isoDayNumber => index + 1;

  /// The day [days] days later in the week, earlier when negative.
  DayOfWeek plus(int days) => values[(index + days) % 7];

  /// How many days lie from this day forward to [other], from 0 to 6.
  int daysUntil(DayOfWeek other) => (other.index - index) % 7;
}
