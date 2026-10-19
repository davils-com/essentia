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

/// How often a recurrence rule repeats, the `FREQ` of RFC 5545.
///
/// The frequencies are ordered from the finest to the coarsest, so
/// `index` compares them.
enum RecurrenceFrequency {
  /// Every second.
  secondly('SECONDLY'),

  /// Every minute.
  minutely('MINUTELY'),

  /// Every hour.
  hourly('HOURLY'),

  /// Every day.
  daily('DAILY'),

  /// Every week.
  weekly('WEEKLY'),

  /// Every month.
  monthly('MONTHLY'),

  /// Every year.
  yearly('YEARLY');

  /// Creates the frequency written as [token].
  const RecurrenceFrequency(this.token);

  /// The frequency of [token], such as `WEEKLY`, ignoring case, or `null`.
  static RecurrenceFrequency? ofToken(String token) {
    final String upper = token.toUpperCase();
    for (final RecurrenceFrequency frequency in values) {
      if (frequency.token == upper) {
        return frequency;
      }
    }
    return null;
  }

  /// How RFC 5545 writes the frequency.
  final String token;

  /// Whether the frequency repeats within a day.
  bool get isTimeBased => index < daily.index;
}
