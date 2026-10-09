/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/time/clock.dart';
import 'package:meta/meta.dart';

/// A date without a time of day and without a time zone, Kotlin's
/// `kotlinx.datetime.LocalDate`: the day a calendar shows.
///
/// Arithmetic on it counts days, months and years and never meets the
/// shifts of daylight saving time that `DateTime` days are subject to.
/// The calendar is the proleptic Gregorian one; months and days count
/// from 1, and [dayOfWeek] numbers Monday 1 and Sunday 7, as
/// `DateTime.weekday` does.
@immutable
final class LocalDate implements Comparable<LocalDate> {
  /// The date of [day] in [month] of [year].
  ///
  /// Throws an [ArgumentError] for a month outside 1 to 12 or a day the
  /// month does not have.
  factory LocalDate(int year, int month, int day) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'Must be from 1 to 12');
    }
    final int length = _lengthOf(year, month);
    if (day < 1 || day > length) {
      throw ArgumentError.value(day, 'day', 'Must be from 1 to $length');
    }
    return LocalDate._(year, month, day);
  }

  /// The date [days] days after 1970-01-01, before it when negative.
  factory LocalDate.fromEpochDays(int days) {
    final int shifted = days + 719468;
    final int era = (shifted >= 0 ? shifted : shifted - 146096) ~/ 146097;
    final int dayOfEra = shifted - era * 146097;
    final int yearOfEra =
        (dayOfEra -
            dayOfEra ~/ 1460 +
            dayOfEra ~/ 36524 -
            dayOfEra ~/ 146096) ~/
        365;
    final int dayOfYear =
        dayOfEra - (365 * yearOfEra + yearOfEra ~/ 4 - yearOfEra ~/ 100);
    final int monthIndex = (5 * dayOfYear + 2) ~/ 153;
    final int day = dayOfYear - (153 * monthIndex + 2) ~/ 5 + 1;
    final int month = monthIndex < 10 ? monthIndex + 3 : monthIndex - 9;
    final int year = yearOfEra + era * 400 + (month <= 2 ? 1 : 0);
    return LocalDate._(year, month, day);
  }

  /// The date of [dateTime] as it reads, in its own zone - local or UTC.
  factory LocalDate.fromDateTime(DateTime dateTime) =>
      LocalDate._(dateTime.year, dateTime.month, dateTime.day);

  /// The date it is now in the zone of this device, read from [clock];
  /// in UTC when not [local].
  factory LocalDate.today({Clock clock = Clock.system, bool local = true}) {
    final DateTime now = clock.now();
    return LocalDate.fromDateTime(local ? now.toLocal() : now);
  }

  /// Creates the date of valid parts.
  const LocalDate._(this.year, this.month, this.day);

  /// Reads a date written as ISO 8601 does: `2026-10-08`, with a sign and
  /// more digits for years beyond 9999 or before 0.
  ///
  /// Throws a [FormatException] for any other text.
  factory LocalDate.parse(String text) {
    final RegExpMatch? match = RegExp(r'^([+-]?\d{4,})-(\d{2})-(\d{2})$')
        .firstMatch(text);
    if (match == null) {
      throw FormatException('Not a date', text);
    }
    final int year = int.parse(match.group(1)!);
    final int month = int.parse(match.group(2)!);
    final int day = int.parse(match.group(3)!);
    if (month < 1 || month > 12 || day < 1 || day > _lengthOf(year, month)) {
      throw FormatException('Not a date', text);
    }
    return LocalDate._(year, month, day);
  }

  /// The year.
  final int year;

  /// The month, from 1 for January to 12 for December.
  final int month;

  /// The day of the month, from 1.
  final int day;

  /// Whether [year] has a 29th of February.
  static bool isLeap(int year) =>
      year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

  /// How many days [month] of [year] has.
  static int _lengthOf(int year, int month) => switch (month) {
    2 => isLeap(year) ? 29 : 28,
    4 || 6 || 9 || 11 => 30,
    int() => 31,
  };

  /// How many days lie between 1970-01-01 and this date, negative before.
  int get epochDays {
    final int y = month <= 2 ? year - 1 : year;
    final int era = (y >= 0 ? y : y - 399) ~/ 400;
    final int yearOfEra = y - era * 400;
    final int dayOfYear =
        (153 * (month > 2 ? month - 3 : month + 9) + 2) ~/ 5 + day - 1;
    final int dayOfEra =
        yearOfEra * 365 + yearOfEra ~/ 4 - yearOfEra ~/ 100 + dayOfYear;
    return era * 146097 + dayOfEra - 719468;
  }

  /// The day of the week, from 1 for Monday to 7 for Sunday.
  int get dayOfWeek => (epochDays + 3) % 7 + 1;

  /// The day of the year, from 1 for the 1st of January.
  int get dayOfYear => epochDays - LocalDate._(year, 1, 1).epochDays + 1;

  /// Whether the year of this date has a 29th of February.
  bool get isLeapYear => isLeap(year);

  /// How many days the month of this date has.
  int get lengthOfMonth => _lengthOf(year, month);

  /// How many days the year of this date has.
  int get lengthOfYear => isLeapYear ? 366 : 365;

  /// The first day of the month of this date.
  LocalDate get firstDayOfMonth => LocalDate._(year, month, 1);

  /// The last day of the month of this date.
  LocalDate get lastDayOfMonth => LocalDate._(year, month, lengthOfMonth);

  /// The number of the week of this date as ISO 8601 counts: weeks start
  /// on Monday and the first week holds the year's first Thursday.
  int get isoWeekNumber {
    final LocalDate thursday = plusDays(4 - dayOfWeek);
    return (thursday.dayOfYear - 1) ~/ 7 + 1;
  }

  /// The date [days] days later, earlier when negative.
  LocalDate plusDays(int days) => LocalDate.fromEpochDays(epochDays + days);

  /// The date [months] months later, earlier when negative, on the same
  /// day or on the last day of a shorter month.
  LocalDate plusMonths(int months) {
    final int index = year * 12 + (month - 1) + months;
    final int targetYear = index >= 0 ? index ~/ 12 : (index - 11) ~/ 12;
    final int targetMonth = index - targetYear * 12 + 1;
    final int length = _lengthOf(targetYear, targetMonth);
    return LocalDate._(targetYear, targetMonth, day > length ? length : day);
  }

  /// The date [years] years later, earlier when negative; the 29th of
  /// February becomes the 28th in a year without it.
  LocalDate plusYears(int years) => plusMonths(years * 12);

  /// The first day of the week of this date, for weeks that start on
  /// [firstDayOfWeek], numbered from 1 for Monday to 7 for Sunday.
  LocalDate startOfWeek(int firstDayOfWeek) =>
      plusDays(-((dayOfWeek - firstDayOfWeek + 7) % 7));

  /// How many days lie from this date to [other], negative when [other]
  /// is earlier.
  int daysUntil(LocalDate other) => other.epochDays - epochDays;

  /// How many whole months lie from this date to [other], negative when
  /// [other] is earlier.
  int monthsUntil(LocalDate other) {
    final int whole = (other.year - year) * 12 + other.month - month;
    if (whole > 0 && other.day < day) {
      return whole - 1;
    }
    if (whole < 0 && other.day > day) {
      return whole + 1;
    }
    return whole;
  }

  /// The start of this date as a `DateTime`, in the zone of this device or
  /// in UTC.
  DateTime toDateTime({bool utc = false}) =>
      utc ? DateTime.utc(year, month, day) : DateTime(year, month, day);

  /// Whether this date comes before [other].
  bool isBefore(LocalDate other) => compareTo(other) < 0;

  /// Whether this date comes after [other].
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  /// Orders dates by time.
  @override
  int compareTo(LocalDate other) => epochDays.compareTo(other.epochDays);

  /// Whether [other] is the same date.
  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  /// A hash of the date.
  @override
  int get hashCode => Object.hash(year, month, day);

  /// The date as ISO 8601 writes it, such as `2026-10-08`.
  @override
  String toString() {
    final String digits = year.abs().toString().padLeft(4, '0');
    final sign = year < 0 ? '-' : (year > 9999 ? '+' : '');
    final String monthText = month.toString().padLeft(2, '0');
    final String dayText = day.toString().padLeft(2, '0');
    return '$sign$digits-$monthText-$dayText';
  }
}
