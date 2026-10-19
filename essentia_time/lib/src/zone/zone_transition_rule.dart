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
import 'package:essentia_time/src/date/local_date.dart';
import 'package:essentia_time/src/date/month.dart';
import 'package:essentia_time/src/zone/utc_offset.dart';
import 'package:essentia_time/src/zone/zone_time_definition.dart';
import 'package:meta/meta.dart';

/// A shift of the clocks that comes back every year, such as "the last
/// Sunday of March at 01:00 UTC, to standard time plus one hour".
///
/// The day is [day] of [month], counted from the end when negative, so -1
/// is the last day. With a [dayOfWeek], it is the first such weekday on or
/// after that day, or the last on or before it when [onOrBefore]: the last
/// Sunday is day -1, Sunday, on or before; the second Sunday is day 8,
/// Sunday.
@immutable
final class ZoneTransitionRule {
  /// The yearly shift to [offsetAfter] at [timeOfDay] seconds after the
  /// start of the day, read on the clock [definition] names.
  ///
  /// [timeOfDay] may be negative or beyond a day, as the time zone
  /// database allows.
  ///
  /// Throws an [ArgumentError] for a day of 0 or beyond 31 either way.
  factory ZoneTransitionRule({
    required Month month,
    required int day,
    required Duration timeOfDay,
    required UtcOffset offsetAfter,
    DayOfWeek? dayOfWeek,
    bool onOrBefore = false,
    ZoneTimeDefinition definition = ZoneTimeDefinition.wall,
  }) {
    if (day == 0 || day.abs() > 31) {
      throw ArgumentError.value(day, 'day', 'Must be from 1 to 31 either way');
    }
    return ZoneTransitionRule._(
      month,
      day,
      dayOfWeek,
      onOrBefore,
      timeOfDay.inSeconds,
      definition,
      offsetAfter,
    );
  }

  /// Creates the rule of checked parts.
  const ZoneTransitionRule._(
    this.month,
    this.day,
    this.dayOfWeek,
    this.onOrBefore,
    this.timeOfDaySeconds,
    this.definition,
    this.offsetAfter,
  );

  /// The month of the shift.
  final Month month;

  /// The day of the month, from the end when negative.
  final int day;

  /// The weekday the shift falls on, or `null` for exactly [day].
  final DayOfWeek? dayOfWeek;

  /// Whether the weekday lies on or before [day] rather than on or after.
  final bool onOrBefore;

  /// The time of the shift in seconds after the start of the day.
  final int timeOfDaySeconds;

  /// The clock the time is read on.
  final ZoneTimeDefinition definition;

  /// The offset from the shift on.
  final UtcOffset offsetAfter;

  /// The time of the shift after the start of the day.
  Duration get timeOfDay => Duration(seconds: timeOfDaySeconds);

  /// The date of the shift in [year].
  LocalDate dateIn(int year) {
    final first = LocalDate.of(year, month, 1);
    final LocalDate anchor = day > 0
        ? first.plusDays(day - 1)
        : first.lastDayOfMonth.plusDays(day + 1);
    final DayOfWeek? weekday = dayOfWeek;
    if (weekday == null) {
      return anchor;
    }
    if (onOrBefore) {
      return anchor.plusDays(-weekday.daysUntil(anchor.dayOfWeek));
    }
    return anchor.plusDays(anchor.dayOfWeek.daysUntil(weekday));
  }

  /// Whether [other] is the same rule.
  @override
  bool operator ==(Object other) =>
      other is ZoneTransitionRule &&
      other.month == month &&
      other.day == day &&
      other.dayOfWeek == dayOfWeek &&
      other.onOrBefore == onOrBefore &&
      other.timeOfDaySeconds == timeOfDaySeconds &&
      other.definition == definition &&
      other.offsetAfter == offsetAfter;

  /// A hash of the rule.
  @override
  int get hashCode => Object.hash(
    month,
    day,
    dayOfWeek,
    onOrBefore,
    timeOfDaySeconds,
    definition,
    offsetAfter,
  );

  /// Describes the rule, such as `march -1 sunday<= 3600s utc -> +02:00`.
  @override
  String toString() {
    final DayOfWeek? weekday = dayOfWeek;
    final on = weekday == null
        ? '$day'
        : '$day ${weekday.name}${onOrBefore ? '<=' : '>='}';
    return '${month.name} $on ${timeOfDaySeconds}s ${definition.name} '
        '-> $offsetAfter';
  }
}
