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

/// Covers months of years and the ranges of dates and months.
void main() {
  group('YearMonth', () {
    test('validates and exposes its parts', () {
      final month = YearMonth(2024, 2);

      expect(month.month, Month.february);
      expect(month.numberOfDays, 29);
      expect(YearMonth(2026, 2).numberOfDays, 28);
      expect(month.firstDay, LocalDate(2024, 2, 1));
      expect(month.lastDay, LocalDate(2024, 2, 29));
      expect(month.days.length, 29);
      expect(month.onDay(10), LocalDate(2024, 2, 10));
      expect(YearMonth.of(2026, Month.october), YearMonth(2026, 10));
      expect(() => YearMonth(2026, 13), throwsArgumentError);
      expect(() => month.onDay(30), throwsArgumentError);
    });

    test('counts months from the epoch both ways', () {
      expect(YearMonth(1970, 1).epochMonths, 0);
      expect(YearMonth(1969, 12).epochMonths, -1);
      expect(YearMonth.fromEpochMonths(-1), YearMonth(1969, 12));
      expect(YearMonth.fromEpochMonths(681), YearMonth(2026, 10));
      expect(YearMonth(2026, 11).plusMonths(3), YearMonth(2027, 2));
      expect(YearMonth(2026, 1).plusMonths(-1), YearMonth(2025, 12));
      expect(YearMonth(2026, 10).plusYears(-2), YearMonth(2024, 10));
      expect(YearMonth(2026, 10).monthsUntil(YearMonth(2025, 10)), -12);
      expect(LocalDate(2026, 10, 9).yearMonth, YearMonth(2026, 10));
    });

    test('orders, compares and writes ISO 8601 text', () {
      final october = YearMonth(2026, 10);

      expect(october.isBefore(YearMonth(2026, 11)), isTrue);
      expect(october.isAfter(YearMonth(2026, 9)), isTrue);
      expect(october.compareTo(YearMonth(2026, 10)), 0);
      expect(october.hashCode, YearMonth(2026, 10).hashCode);
      expect(october.toString(), '2026-10');
      expect(YearMonth(-1, 3).toString(), '-0001-03');
      expect(YearMonth.parse('2026-10'), october);
      expect(() => YearMonth.parse('2026-13'), throwsFormatException);
      expect(() => YearMonth.parse('2026-1'), throwsFormatException);
    });
  });

  group('LocalDateRange', () {
    final LocalDateRange week = LocalDate(
      2026,
      10,
      5,
    ).rangeTo(LocalDate(2026, 10, 11));

    test('iterates, indexes and measures without iterating', () {
      expect(week.length, 7);
      expect(week.first, LocalDate(2026, 10, 5));
      expect(week.last, LocalDate(2026, 10, 11));
      expect(week.elementAt(2), LocalDate(2026, 10, 7));
      expect(week.endExclusive, LocalDate(2026, 10, 12));
      expect(week.isNotEmpty, isTrue);
      expect(() => week.elementAt(7), throwsRangeError);
      expect(
        LocalDate(2026, 10, 5).rangeUntil(LocalDate(2026, 10, 7)).toList(),
        <LocalDate>[LocalDate(2026, 10, 5), LocalDate(2026, 10, 6)],
      );
    });

    test('contains, overlaps and intersects', () {
      final later = LocalDateRange(
        LocalDate(2026, 10, 10),
        LocalDate(2026, 10, 20),
      );
      final empty = LocalDateRange(
        LocalDate(2026, 10, 2),
        LocalDate(2026, 10, 1),
      );

      expect(week.contains(LocalDate(2026, 10, 11)), isTrue);
      expect(week.contains(LocalDate(2026, 10, 12)), isFalse);
      expect(week.contains(Object()), isFalse);
      expect(week.overlaps(later), isTrue);
      expect(
        week.intersect(later),
        LocalDateRange(LocalDate(2026, 10, 10), LocalDate(2026, 10, 11)),
      );
      expect(week.intersect(empty), isNull);
      expect(empty.isEmpty, isTrue);
      expect(empty.length, 0);
      expect(
        empty,
        LocalDateRange(LocalDate(2027, 1, 2), LocalDate(2027, 1, 1)),
      );
      expect(empty.hashCode, 0);
    });

    test('compares and describes itself', () {
      expect(
        week,
        LocalDateRange(LocalDate(2026, 10, 5), LocalDate(2026, 10, 11)),
      );
      expect(
        week.hashCode,
        LocalDateRange(
          LocalDate(2026, 10, 5),
          LocalDate(2026, 10, 11),
        ).hashCode,
      );
      expect(week.toString(), '2026-10-05..2026-10-11');
    });
  });

  group('YearMonthRange', () {
    final YearMonthRange quarter = YearMonth(
      2026,
      11,
    ).rangeTo(YearMonth(2027, 1));

    test('iterates, indexes and contains', () {
      expect(quarter.length, 3);
      expect(quarter.toList(), <YearMonth>[
        YearMonth(2026, 11),
        YearMonth(2026, 12),
        YearMonth(2027, 1),
      ]);
      expect(quarter.elementAt(1), YearMonth(2026, 12));
      expect(() => quarter.elementAt(3), throwsRangeError);
      expect(quarter.contains(YearMonth(2026, 12)), isTrue);
      expect(quarter.contains(YearMonth(2027, 2)), isFalse);
      expect(quarter.isNotEmpty, isTrue);
      expect(YearMonth(2026, 1).rangeUntil(YearMonth(2026, 1)).isEmpty, isTrue);
    });

    test('compares and describes itself', () {
      final empty = YearMonthRange(YearMonth(2026, 2), YearMonth(2026, 1));

      expect(quarter, YearMonthRange(YearMonth(2026, 11), YearMonth(2027, 1)));
      expect(
        quarter.hashCode,
        YearMonthRange(YearMonth(2026, 11), YearMonth(2027, 1)).hashCode,
      );
      expect(empty, YearMonthRange(YearMonth(2027, 2), YearMonth(2027, 1)));
      expect(empty.length, 0);
      expect(empty.hashCode, 0);
      expect(quarter.toString(), '2026-11..2027-01');
    });
  });
}
