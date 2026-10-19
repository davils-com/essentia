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

import 'package:essentia_time/src/date/day_of_week.dart';
import 'package:meta/meta.dart';

/// A weekday of a recurrence rule, the `BYDAY` of RFC 5545: every Monday,
/// or with an [ordinal] the second Monday, or the last Sunday with -1.
@immutable
final class RecurrenceWeekday {
  /// The weekday [day], every one or only the [ordinal]th of the month or
  /// year, counted from the end when negative.
  const RecurrenceWeekday(this.day, [this.ordinal]);

  /// Reads a weekday as RFC 5545 writes it: `MO`, `2MO`, `+2MO`, `-1SU`.
  ///
  /// Throws a [FormatException] for any other text.
  factory RecurrenceWeekday.parse(String text) {
    final RegExpMatch? match = RegExp(
      r'^([+-]?\d{1,2})?(MO|TU|WE|TH|FR|SA|SU)$',
      caseSensitive: false,
    ).firstMatch(text.trim());
    if (match == null) {
      throw FormatException('Not a weekday', text);
    }
    final String? ordinal = match.group(1);
    return RecurrenceWeekday(
      DayOfWeek.values[_tokens.indexOf(match.group(2)!.toUpperCase())],
      ordinal == null ? null : int.parse(ordinal),
    );
  }

  /// How RFC 5545 writes the days of the week, from Monday.
  static const _tokens = <String>['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  /// How RFC 5545 writes [day].
  static String tokenOf(DayOfWeek day) => _tokens[day.index];

  /// The weekday.
  final DayOfWeek day;

  /// Which of the weekdays of the month or year, from the end when
  /// negative, or `null` for every one.
  final int? ordinal;

  /// Whether [other] is the same weekday with the same ordinal.
  @override
  bool operator ==(Object other) =>
      other is RecurrenceWeekday &&
      other.day == day &&
      other.ordinal == ordinal;

  /// A hash of the weekday.
  @override
  int get hashCode => Object.hash(day, ordinal);

  /// The weekday as RFC 5545 writes it, such as `-1SU`.
  @override
  String toString() => '${ordinal ?? ''}${tokenOf(day)}';
}
