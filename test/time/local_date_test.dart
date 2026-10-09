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

    expect(date.dayOfWeek, DateTime.thursday);
    expect(LocalDate(1969, 12, 28).dayOfWeek, DateTime.sunday);
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
      LocalDate(2026, 10, 8).startOfWeek(DateTime.monday),
      LocalDate(2026, 10, 5),
    );
    expect(
      LocalDate(2026, 10, 8).startOfWeek(DateTime.sunday),
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
    final clock = _FixedClock(DateTime.utc(2026, 10, 8, 12));

    expect(LocalDate.today(clock: clock, local: false), LocalDate(2026, 10, 8));
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
}
