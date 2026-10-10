/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:test/test.dart';

part '_fixed_clock.dart';

/// Covers local dates: validation, epoch days, calendar arithmetic, week
/// numbers, ordering and ISO 8601 text.
void main() {
  test('refuses months and days that do not exist', () {
    expect(() => LocalDate(2026, 13, 1), throwsArgumentError);
    expect(() => LocalDate(2026, 0, 1), throwsArgumentError);
    expect(() => LocalDate(2026, 2, 29), throwsArgumentError);
    expect(() => LocalDate(2026, 4, 31), throwsArgumentError);
    expect(LocalDate(2024, 2, 29).day, 29);
    expect(LocalDate(2000, 2, 29).isLeapYear, isTrue);
    expect(LocalDate.isLeap(1900), isFalse);
  });

  test('counts days from the epoch both ways', () {
    expect(LocalDate(1970, 1, 1).epochDays, 0);
    expect(LocalDate(2026, 10, 8).epochDays, 20734);
    expect(LocalDate(1969, 12, 31).epochDays, -1);
    expect(LocalDate.fromEpochDays(-719528), LocalDate(0, 1, 1));
    for (var days = -800000; days < 800000; days += 9973) {
      expect(LocalDate.fromEpochDays(days).epochDays, days);
    }
  });

  test('knows its weekday, its day of the year and its month', () {
    final date = LocalDate(2026, 10, 8);

    expect(date.dayOfWeek, DayOfWeek.thursday);
    expect(LocalDate(1969, 12, 28).dayOfWeek, DayOfWeek.sunday);
    expect(date.dayOfYear, 281);
    expect(date.lengthOfMonth, 31);
    expect(LocalDate(2026, 2, 3).lengthOfMonth, 28);
    expect(date.lengthOfYear, 365);
    expect(LocalDate(2024, 3, 1).lengthOfYear, 366);
    expect(date.firstDayOfMonth, LocalDate(2026, 10, 1));
    expect(date.lastDayOfMonth, LocalDate(2026, 10, 31));
  });

  test('numbers weeks as ISO 8601 does', () {
    expect(LocalDate(2026, 1, 1).isoWeekNumber, 1);
    expect(LocalDate(2021, 1, 3).isoWeekNumber, 53);
    expect(LocalDate(2024, 12, 30).isoWeekNumber, 1);
    expect(LocalDate(2026, 10, 8).isoWeekNumber, 41);
  });

  test('adds days, months and years', () {
    final date = LocalDate(2024, 1, 31);

    expect(date.plusDays(1), LocalDate(2024, 2, 1));
    expect(date.plusDays(-31), LocalDate(2023, 12, 31));
    expect(date.plusMonths(1), LocalDate(2024, 2, 29));
    expect(date.plusMonths(13), LocalDate(2025, 2, 28));
    expect(date.plusMonths(-1), LocalDate(2023, 12, 31));
    expect(LocalDate(1, 1, 15).plusMonths(-13), LocalDate(-1, 12, 15));
    expect(LocalDate(2024, 2, 29).plusYears(1), LocalDate(2025, 2, 28));
    expect(
      LocalDate(2026, 10, 8).startOfWeek(DayOfWeek.monday),
      LocalDate(2026, 10, 5),
    );
    expect(
      LocalDate(2026, 10, 8).startOfWeek(DayOfWeek.sunday),
      LocalDate(2026, 10, 4),
    );
  });

  test('measures days and whole months between dates', () {
    final start = LocalDate(2026, 1, 31);

    expect(start.daysUntil(LocalDate(2026, 3, 1)), 29);
    expect(LocalDate(2026, 3, 1).daysUntil(start), -29);
    expect(start.monthsUntil(LocalDate(2026, 2, 28)), 0);
    expect(start.monthsUntil(LocalDate(2026, 3, 31)), 2);
    expect(LocalDate(2026, 3, 1).monthsUntil(LocalDate(2026, 1, 31)), -1);
    expect(LocalDate(2026, 3, 31).monthsUntil(start), -2);
  });

  test('orders, compares and converts', () {
    final early = LocalDate(2026, 1, 1);
    final late = LocalDate(2026, 1, 2);

    expect(early.isBefore(late), isTrue);
    expect(late.isAfter(early), isTrue);
    expect(early.compareTo(LocalDate(2026, 1, 1)), 0);
    expect(early, LocalDate(2026, 1, 1));
    expect(early.hashCode, LocalDate(2026, 1, 1).hashCode);
    expect(early == late, isFalse);
    expect(early.toDateTime(), DateTime(2026));
    expect(early.toDateTime(utc: true), DateTime.utc(2026));
    expect(
      LocalDate.fromDateTime(DateTime.utc(2026, 5, 6, 23)),
      LocalDate(2026, 5, 6),
    );
  });

  test('reads today from a clock', () {
    final clock = _FixedClock(Instant.parse('2026-10-08T23:30:00Z'));

    expect(
      LocalDate.today(clock: clock, timeZone: TimeZone.utc),
      LocalDate(2026, 10, 8),
    );
    expect(
      LocalDate.today(clock: clock, timeZone: TimeZone.of('+02:00')),
      LocalDate(2026, 10, 9),
    );
    expect(LocalDate.today(clock: clock).year, 2026);
    expect(LocalDate.today().year, greaterThan(2000));
  });

  test('writes and reads ISO 8601 text', () {
    expect(LocalDate(2026, 10, 8).toString(), '2026-10-08');
    expect(LocalDate(12026, 1, 1).toString(), '+12026-01-01');
    expect(LocalDate(-44, 3, 15).toString(), '-0044-03-15');
    expect(LocalDate(5, 1, 1).toString(), '0005-01-01');
    expect(LocalDate.parse('2026-10-08'), LocalDate(2026, 10, 8));
    expect(LocalDate.parse('-0044-03-15'), LocalDate(-44, 3, 15));
    expect(() => LocalDate.parse('2026-02-30'), throwsFormatException);
    expect(() => LocalDate.parse('08.10.2026'), throwsFormatException);
  });

  test('builds from a month and knows its month and ISO week year', () {
    expect(LocalDate.of(2026, Month.october, 9), LocalDate(2026, 10, 9));
    expect(LocalDate(2026, 10, 9).month, Month.october);
    expect(LocalDate(2026, 10, 9).monthNumber, 10);
    expect(LocalDate(2027, 1, 1).isoWeekNumber, 53);
    expect(LocalDate(2027, 1, 1).isoWeekYear, 2026);
    expect(LocalDate(2024, 12, 30).isoWeekYear, 2025);
    expect(LocalDate(2026, 6, 1).isoWeekYear, 2026);
  });

  test('adds units and periods as Kotlin does', () {
    final date = LocalDate(2024, 1, 31);

    expect(date.plus(2, DateTimeUnit.week), LocalDate(2024, 2, 14));
    expect(date.plus(1, DateTimeUnit.month), LocalDate(2024, 2, 29));
    expect(date.minus(1, DateTimeUnit.quarter), LocalDate(2023, 10, 31));
    expect(
      date.plusPeriod(DatePeriod(months: 1, days: 1)),
      LocalDate(2024, 3, 1),
    );
    expect(
      LocalDate(2024, 3, 1).minusPeriod(DatePeriod(months: 1, days: 1)),
      LocalDate(2024, 1, 31),
    );
  });

  test('measures in units and periods', () {
    final start = LocalDate(2024, 1, 31);
    final end = LocalDate(2026, 3, 2);

    expect(start.until(end, DateTimeUnit.day), 761);
    expect(start.until(end, DateTimeUnit.week), 108);
    expect(start.until(end, DateTimeUnit.month), 25);
    expect(start.until(end, DateTimeUnit.year), 2);
    expect(start.yearsUntil(end), 2);
    expect(end.yearsUntil(start), -2);
    expect(start.periodUntil(end), DatePeriod(years: 2, months: 1, days: 2));
    expect(end.periodUntil(start), DatePeriod(years: -2, months: -1, days: -2));
  });

  test('joins a time and finds the start of its day in a zone', () {
    final date = LocalDate(2026, 3, 29);

    expect(date.atTime(LocalTime(9, 30)), LocalDateTime.of(2026, 3, 29, 9, 30));
    expect(
      date.atStartOfDayIn(TimeZone.of('Europe/Berlin')),
      Instant.parse('2026-03-28T23:00:00Z'),
    );
  });
}
