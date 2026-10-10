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

/// Covers the units of time and the periods of calendar and clock time.
void main() {
  group('DateTimeUnit', () {
    test('holds its length and multiplies', () {
      expect(DateTimeUnit.hour.nanoseconds, 3600000000000);
      expect(DateTimeUnit.minute.duration, const Duration(minutes: 1));
      expect(DateTimeUnit.week.days, 7);
      expect(DateTimeUnit.quarter.months, 3);
      expect(DateTimeUnit.hour.times(2), TimeBasedUnit(7200000000000));
      expect(DateTimeUnit.day.times(7), DateTimeUnit.week);
      expect(DateTimeUnit.year.times(100), DateTimeUnit.century);
      expect(() => TimeBasedUnit(0), throwsArgumentError);
      expect(() => DayBasedUnit(-1), throwsArgumentError);
      expect(() => MonthBasedUnit(0), throwsArgumentError);
      expect(() => DateTimeUnit.day.times(0), throwsArgumentError);
    });

    test('names itself like Kotlin', () {
      expect(DateTimeUnit.nanosecond.toString(), 'NANOSECOND');
      expect(DateTimeUnit.microsecond.toString(), 'MICROSECOND');
      expect(DateTimeUnit.millisecond.toString(), 'MILLISECOND');
      expect(DateTimeUnit.second.toString(), 'SECOND');
      expect(DateTimeUnit.minute.times(15).toString(), '15-MINUTE');
      expect(DateTimeUnit.hour.toString(), 'HOUR');
      expect(TimeBasedUnit(1500).toString(), '1500-NANOSECOND');
      expect(DateTimeUnit.day.toString(), 'DAY');
      expect(DateTimeUnit.day.times(3).toString(), '3-DAY');
      expect(DateTimeUnit.week.times(2).toString(), '2-WEEK');
      expect(DateTimeUnit.month.toString(), 'MONTH');
      expect(DateTimeUnit.quarter.toString(), 'QUARTER');
      expect(DateTimeUnit.year.toString(), 'YEAR');
      expect(DateTimeUnit.century.times(2).toString(), '2-CENTURY');
      expect(DateTimeUnit.month.times(2).toString(), '2-MONTH');
    });

    test('compares by length', () {
      expect(DateTimeUnit.hour.hashCode, TimeBasedUnit(3600000000000).hashCode);
      expect(DateTimeUnit.week.hashCode, DayBasedUnit(7).hashCode);
      expect(DateTimeUnit.year.hashCode, MonthBasedUnit(12).hashCode);
      expect(DateTimeUnit.week == DateTimeUnit.day, isFalse);
    });
  });

  group('DateTimePeriod', () {
    test('normalises as Kotlin does', () {
      final period = DateTimePeriod(
        years: 1,
        months: 14,
        days: 3,
        hours: 25,
        minutes: 61,
        seconds: 61,
        nanoseconds: 1500000000,
      );

      expect(period.years, 2);
      expect(period.months, 2);
      expect(period.totalMonths, 26);
      expect(period.days, 3);
      expect(period.hours, 26);
      expect(period.minutes, 2);
      expect(period.seconds, 2);
      expect(period.nanoseconds, 500000000);
      expect(DateTimePeriod(hours: 1, nanoseconds: -1).seconds, 59);
      expect(DateTimePeriod(hours: -1, nanoseconds: 1).nanoseconds, -999999999);
      expect(DateTimePeriod(days: 2), isA<DatePeriod>());
      expect(DateTimePeriod(hours: 2), isNot(isA<DatePeriod>()));
      expect(
        DateTimePeriod(minutes: 1).timeDuration,
        const Duration(minutes: 1),
      );
    });

    test('negates and adds part by part', () {
      final period = DateTimePeriod(months: 1, days: -2, hours: 3);

      expect(-period, DateTimePeriod(months: -1, days: 2, hours: -3));
      expect(period + DatePeriod(days: 2), DateTimePeriod(months: 1, hours: 3));
      expect(-DatePeriod(years: 1), DatePeriod(months: -12));
    });

    test('writes ISO 8601 text as Kotlin does', () {
      expect(DateTimePeriod().toString(), 'P0D');
      expect(
        DateTimePeriod(
          years: 1,
          months: 2,
          days: 3,
          hours: 4,
          minutes: 5,
          seconds: 6,
        ).toString(),
        'P1Y2M3DT4H5M6S',
      );
      expect(DateTimePeriod(days: -1, hours: -2).toString(), '-P1DT2H');
      expect(DateTimePeriod(days: 1, hours: -2).toString(), 'P1DT-2H');
      expect(
        DateTimePeriod(seconds: 1, nanoseconds: 500000000).toString(),
        'PT1.500000000S',
      );
      expect(DateTimePeriod(nanoseconds: -5).toString(), '-PT0.000000005S');
      expect(
        DateTimePeriod(days: 1, nanoseconds: -5).toString(),
        'P1DT-0.000000005S',
      );
      expect(DatePeriod(months: 3).toString(), 'P3M');
    });

    test('reads ISO 8601 text', () {
      expect(
        DateTimePeriod.parse('P1Y2M3DT4H5M6.5S'),
        DateTimePeriod(
          years: 1,
          months: 2,
          days: 3,
          hours: 4,
          minutes: 5,
          seconds: 6,
          nanoseconds: 500000000,
        ),
      );
      expect(DateTimePeriod.parse('P2W'), DatePeriod(days: 14));
      expect(DateTimePeriod.parse('-P1D'), DatePeriod(days: -1));
      expect(DateTimePeriod.parse('P-1M+2D'), DatePeriod(months: -1, days: 2));
      expect(
        DateTimePeriod.parse('PT-0.5S'),
        DateTimePeriod(nanoseconds: -500000000),
      );
      expect(DateTimePeriod.parse('PT1,25S').nanoseconds, 250000000);
      expect(DatePeriod.parse('P1Y'), DatePeriod(years: 1));
      expect(() => DatePeriod.parse('PT1H'), throwsFormatException);
      expect(() => DateTimePeriod.parse('P'), throwsFormatException);
      expect(() => DateTimePeriod.parse('P1DT'), throwsFormatException);
      expect(() => DateTimePeriod.parse('1D'), throwsFormatException);
    });

    test('compares by its normalised parts', () {
      expect(DateTimePeriod(hours: 1), DateTimePeriod(minutes: 60));
      expect(
        DateTimePeriod(hours: 1).hashCode,
        DateTimePeriod(minutes: 60).hashCode,
      );
      expect(DatePeriod(years: 1) == DatePeriod(months: 13), isFalse);
    });
  });
}
