/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_time/src/date/local_date.dart';
import 'package:essentia_time/src/date/local_date_range.dart';
import 'package:essentia_time/src/date/month.dart';
import 'package:essentia_time/src/date/year_month_range.dart';
import 'package:essentia_time/src/internal/iso_text.dart';
import 'package:essentia_time/src/internal/time_math.dart';
import 'package:meta/meta.dart';

/// A month of a year: October 2026.
@immutable
final class YearMonth implements Comparable<YearMonth> {
  /// Month [monthNumber] of [year].
  ///
  /// Throws an [ArgumentError] for a month outside 1 to 12.
  factory YearMonth(int year, int monthNumber) {
    if (monthNumber < 1 || monthNumber > 12) {
      throw ArgumentError.value(
        monthNumber,
        'monthNumber',
        'Must be from 1 to 12',
      );
    }
    return YearMonth._(year, monthNumber);
  }

  /// [month] of [year].
  factory YearMonth.of(int year, Month month) =>
      YearMonth._(year, month.number);

  /// The month [epochMonths] months after January 1970, before it when
  /// negative.
  factory YearMonth.fromEpochMonths(int epochMonths) {
    final int index = epochMonths + 1970 * 12;
    return YearMonth._(floorDiv(index, 12), floorMod(index, 12) + 1);
  }

  /// Reads a month written as ISO 8601 does: `2026-10`.
  ///
  /// Throws a [FormatException] for any other text.
  factory YearMonth.parse(String text) {
    final RegExpMatch? match = RegExp(r'^([+-]?\d{4,})-(\d{2})$')
        .firstMatch(text);
    if (match == null) {
      throw FormatException('Not a year and month', text);
    }
    final int month = int.parse(match.group(2)!);
    if (month < 1 || month > 12) {
      throw FormatException('Not a year and month', text);
    }
    return YearMonth._(int.parse(match.group(1)!), month);
  }

  /// Creates the month of valid parts.
  const YearMonth._(this.year, this.monthNumber);

  /// The year.
  final int year;

  /// The number of the month, from 1 to 12.
  final int monthNumber;

  /// The month.
  Month get month => Month.of(monthNumber);

  /// How many months lie between January 1970 and this month.
  int get epochMonths => (year - 1970) * 12 + monthNumber - 1;

  /// How many days the month has.
  int get numberOfDays => month.length(leapYear: LocalDate.isLeap(year));

  /// The first day of the month.
  LocalDate get firstDay => LocalDate(year, monthNumber, 1);

  /// The last day of the month.
  LocalDate get lastDay => LocalDate(year, monthNumber, numberOfDays);

  /// Every day of the month.
  LocalDateRange get days => LocalDateRange(firstDay, lastDay);

  /// [day] of this month.
  ///
  /// Throws an [ArgumentError] for a day the month does not have.
  LocalDate onDay(int day) => LocalDate(year, monthNumber, day);

  /// The month [months] months later, earlier when negative.
  YearMonth plusMonths(int months) =>
      YearMonth.fromEpochMonths(epochMonths + months);

  /// The month [years] years later, earlier when negative.
  YearMonth plusYears(int years) => plusMonths(years * 12);

  /// How many months lie from this month to [other].
  int monthsUntil(YearMonth other) => other.epochMonths - epochMonths;

  /// The months from this one up to and including [end].
  YearMonthRange rangeTo(YearMonth end) => YearMonthRange(this, end);

  /// The months from this one up to but excluding [end].
  YearMonthRange rangeUntil(YearMonth end) =>
      YearMonthRange(this, end.plusMonths(-1));

  /// Whether this month comes before [other].
  bool isBefore(YearMonth other) => compareTo(other) < 0;

  /// Whether this month comes after [other].
  bool isAfter(YearMonth other) => compareTo(other) > 0;

  /// Orders months by time.
  @override
  int compareTo(YearMonth other) => epochMonths.compareTo(other.epochMonths);

  /// Whether [other] is the same month.
  @override
  bool operator ==(Object other) =>
      other is YearMonth &&
      other.year == year &&
      other.monthNumber == monthNumber;

  /// A hash of the month.
  @override
  int get hashCode => Object.hash(year, monthNumber);

  /// The month as ISO 8601 writes it, such as `2026-10`.
  @override
  String toString() => '${isoYear(year)}-${twoDigits(monthNumber)}';
}
