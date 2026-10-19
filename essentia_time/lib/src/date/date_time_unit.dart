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

import 'package:meta/meta.dart';

/// A unit to measure time in.
///
/// A [TimeBasedUnit] is a fixed amount of exact time. A [DateBasedUnit]
/// counts on a calendar: a [DayBasedUnit] in days, which can last 23 or 25
/// hours where the clocks shift, and a [MonthBasedUnit] in months, which
/// have different lengths.
@immutable
sealed class DateTimeUnit {
  /// Creates a unit.
  const DateTimeUnit();

  /// One nanosecond.
  static const nanosecond = TimeBasedUnit._(1);

  /// One microsecond.
  static const microsecond = TimeBasedUnit._(1000);

  /// One millisecond.
  static const millisecond = TimeBasedUnit._(1000000);

  /// One second.
  static const second = TimeBasedUnit._(1000000000);

  /// One minute.
  static const minute = TimeBasedUnit._(60000000000);

  /// One hour.
  static const hour = TimeBasedUnit._(3600000000000);

  /// One calendar day.
  static const day = DayBasedUnit._(1);

  /// One week of seven calendar days.
  static const week = DayBasedUnit._(7);

  /// One month.
  static const month = MonthBasedUnit._(1);

  /// One quarter of a year, three months.
  static const quarter = MonthBasedUnit._(3);

  /// One year, twelve months.
  static const year = MonthBasedUnit._(12);

  /// One century, a hundred years.
  static const century = MonthBasedUnit._(1200);

  /// The unit [scalar] times as long.
  ///
  /// Throws an [ArgumentError] unless [scalar] is positive.
  DateTimeUnit times(int scalar);

  /// Throws an [ArgumentError] unless [value] is positive.
  static void _checkPositive(int value, String name) {
    if (value <= 0) {
      throw ArgumentError.value(value, name, 'Must be positive');
    }
  }

  /// [count] of [name], written `NAME` for one and `count-NAME` else.
  static String _describe(int count, String name) =>
      count == 1 ? name : '$count-$name';
}

/// A unit of exact time, a number of [nanoseconds].
final class TimeBasedUnit extends DateTimeUnit {
  /// The unit of [nanoseconds] nanoseconds.
  ///
  /// Throws an [ArgumentError] unless it is positive.
  factory TimeBasedUnit(int nanoseconds) {
    DateTimeUnit._checkPositive(nanoseconds, 'nanoseconds');
    return TimeBasedUnit._(nanoseconds);
  }

  /// Creates the unit of a positive length.
  const TimeBasedUnit._(this.nanoseconds);

  /// The length of the unit in nanoseconds.
  final int nanoseconds;

  /// The length of the unit as a `Duration`, to the microsecond.
  Duration get duration => Duration(microseconds: nanoseconds ~/ 1000);

  /// The unit [scalar] times as long.
  @override
  TimeBasedUnit times(int scalar) {
    DateTimeUnit._checkPositive(scalar, 'scalar');
    return TimeBasedUnit._(nanoseconds * scalar);
  }

  /// Whether [other] is a unit of the same length.
  @override
  bool operator ==(Object other) =>
      other is TimeBasedUnit && other.nanoseconds == nanoseconds;

  /// A hash of the unit.
  @override
  int get hashCode => nanoseconds.hashCode;

  /// Names the unit: `HOUR`, `2-MINUTE`, `NANOSECOND`.
  @override
  String toString() {
    for (final (int length, String name) in _names) {
      if (nanoseconds % length == 0) {
        return DateTimeUnit._describe(nanoseconds ~/ length, name);
      }
    }
    return DateTimeUnit._describe(nanoseconds, 'NANOSECOND');
  }

  /// The names of the units, the longest first.
  static const _names = <(int, String)>[
    (3600000000000, 'HOUR'),
    (60000000000, 'MINUTE'),
    (1000000000, 'SECOND'),
    (1000000, 'MILLISECOND'),
    (1000, 'MICROSECOND'),
  ];
}

/// A unit that counts on a calendar.
sealed class DateBasedUnit extends DateTimeUnit {
  /// Creates a calendar unit.
  const DateBasedUnit();

  /// The unit [scalar] times as long.
  @override
  DateBasedUnit times(int scalar);
}

/// A unit of [days] calendar days.
final class DayBasedUnit extends DateBasedUnit {
  /// The unit of [days] days.
  ///
  /// Throws an [ArgumentError] unless it is positive.
  factory DayBasedUnit(int days) {
    DateTimeUnit._checkPositive(days, 'days');
    return DayBasedUnit._(days);
  }

  /// Creates the unit of a positive number of days.
  const DayBasedUnit._(this.days);

  /// The number of days.
  final int days;

  /// The unit [scalar] times as long.
  @override
  DayBasedUnit times(int scalar) {
    DateTimeUnit._checkPositive(scalar, 'scalar');
    return DayBasedUnit._(days * scalar);
  }

  /// Whether [other] is a unit of the same number of days.
  @override
  bool operator ==(Object other) => other is DayBasedUnit && other.days == days;

  /// A hash of the unit.
  @override
  int get hashCode => days.hashCode;

  /// Names the unit: `DAY`, `WEEK`, `3-DAY`.
  @override
  String toString() => days % 7 == 0
      ? DateTimeUnit._describe(days ~/ 7, 'WEEK')
      : DateTimeUnit._describe(days, 'DAY');
}

/// A unit of [months] months.
final class MonthBasedUnit extends DateBasedUnit {
  /// The unit of [months] months.
  ///
  /// Throws an [ArgumentError] unless it is positive.
  factory MonthBasedUnit(int months) {
    DateTimeUnit._checkPositive(months, 'months');
    return MonthBasedUnit._(months);
  }

  /// Creates the unit of a positive number of months.
  const MonthBasedUnit._(this.months);

  /// The number of months.
  final int months;

  /// The unit [scalar] times as long.
  @override
  MonthBasedUnit times(int scalar) {
    DateTimeUnit._checkPositive(scalar, 'scalar');
    return MonthBasedUnit._(months * scalar);
  }

  /// Whether [other] is a unit of the same number of months.
  @override
  bool operator ==(Object other) =>
      other is MonthBasedUnit && other.months == months;

  /// A hash of the unit.
  @override
  int get hashCode => months.hashCode;

  /// Names the unit: `MONTH`, `QUARTER`, `YEAR`, `CENTURY`.
  @override
  String toString() {
    if (months % 1200 == 0) {
      return DateTimeUnit._describe(months ~/ 1200, 'CENTURY');
    }
    if (months % 12 == 0) {
      return DateTimeUnit._describe(months ~/ 12, 'YEAR');
    }
    if (months % 3 == 0) {
      return DateTimeUnit._describe(months ~/ 3, 'QUARTER');
    }
    return DateTimeUnit._describe(months, 'MONTH');
  }
}
