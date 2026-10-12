/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
