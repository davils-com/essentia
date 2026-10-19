/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_time/essentia_time.dart';
import 'package:test/test.dart';

/// Covers moments: construction, clamping, arithmetic with exact and
/// calendar units, periods between moments, conversions and ISO 8601 text.
void main() {
  final TimeZone berlin = TimeZone.of('Europe/Berlin');

  group('construction', () {
    test('normalises seconds and nanoseconds', () {
      final instant = Instant.fromEpochSeconds(10, -1);

      expect(instant.epochSeconds, 9);
      expect(instant.nanosecondsOfSecond, 999999999);
      expect(Instant.fromEpochSeconds(0, 2500000000).epochSeconds, 2);
      expect(Instant.fromEpochMilliseconds(-1).epochSeconds, -1);
      expect(Instant.fromEpochMilliseconds(-1).nanosecondsOfSecond, 999000000);
    });

    test('clamps beyond its range', () {
      expect(Instant.fromEpochSeconds(1125899906842624), Instant.max);
      expect(Instant.fromEpochSeconds(-1125899906842624), Instant.min);
      expect(Instant.max + const Duration(days: 1), Instant.max);
      expect(Instant.min - const Duration(days: 1), Instant.min);
    });

    test('reads and writes a DateTime', () {
      final dateTime = DateTime.utc(2026, 10, 9, 12, 30, 0, 1, 2);
      final instant = Instant.fromDateTime(dateTime);

      expect(instant.toDateTime(), dateTime);
      expect(instant.toDateTime(local: true).isUtc, isFalse);
      expect(
        Instant.fromDateTime(DateTime.utc(1969, 12, 31, 23, 59, 59, 999)),
        Instant.fromEpochMilliseconds(-1),
      );
    });

    test('knows the distant past and future', () {
      expect(Instant.distantPast.isDistantPast, isTrue);
      expect(Instant.min.isDistantPast, isTrue);
      expect(Instant.distantFuture.isDistantFuture, isTrue);
      expect(Instant.epoch.isDistantPast, isFalse);
      expect(Instant.epoch.isDistantFuture, isFalse);
      expect(Instant.distantFuture.toString(), '+100000-01-01T00:00:00Z');
      expect(
        Instant.distantPast.toString(),
        '-100001-12-31T23:59:59.999999999Z',
      );
    });
  });

  group('epoch milliseconds', () {
    test('rounds down', () {
      expect(Instant.fromEpochSeconds(1, 999999).toEpochMilliseconds(), 1000);
      expect(Instant.fromEpochSeconds(-1, 1).toEpochMilliseconds(), -1000);
    });

    test('clamps to the integers every platform holds', () {
      expect(Instant.max.toEpochMilliseconds(), 9007199254740991);
      expect(Instant.min.toEpochMilliseconds(), -9007199254740991);
    });
  });

  group('arithmetic', () {
    final start = Instant.parse('2026-03-28T12:00:00Z');

    test('adds and subtracts durations', () {
      expect(
        start + const Duration(hours: 36, microseconds: 1),
        Instant.parse('2026-03-30T00:00:00.000001Z'),
      );
      expect(
        start - const Duration(microseconds: 1),
        Instant.parse('2026-03-28T11:59:59.999999Z'),
      );
      expect(
        Instant.parse('2026-03-30T00:00:00Z').difference(start),
        const Duration(hours: 36),
      );
      expect(
        start.difference(Instant.parse('2026-03-28T12:00:00.000001Z')),
        const Duration(microseconds: -1),
      );
    });

    test('adds exact units without a zone', () {
      expect(
        start.plus(90, DateTimeUnit.minute),
        Instant.parse('2026-03-28T13:30:00Z'),
      );
      expect(start.plus(3, DateTimeUnit.nanosecond).nanosecondsOfSecond, 3);
      expect(
        start.minus(1, DateTimeUnit.nanosecond),
        Instant.parse('2026-03-28T11:59:59.999999999Z'),
      );
      expect(
        () => Instant.max.plus(1, DateTimeUnit.hour),
        throwsA(isA<DateTimeArithmeticException>()),
      );
    });

    test('adds calendar units on the clocks of a zone', () {
      const DateTimeUnit day = DateTimeUnit.day;

      expect(
        start.plus(1, day, timeZone: berlin),
        Instant.parse('2026-03-29T11:00:00Z'),
      );
      expect(
        start.plus(1, DateTimeUnit.month, timeZone: berlin),
        Instant.parse('2026-04-28T11:00:00Z'),
      );
      expect(
        start.minus(1, DateTimeUnit.year, timeZone: TimeZone.utc),
        Instant.parse('2025-03-28T12:00:00Z'),
      );
      expect(() => start.plus(1, day), throwsArgumentError);
    });

    test('adds periods: dates on the clocks, time as exact time', () {
      final period = DateTimePeriod(days: 1, hours: 1);

      expect(
        start.plusPeriod(period, berlin),
        Instant.parse('2026-03-29T12:00:00Z'),
      );
      expect(
        Instant.parse('2026-03-29T12:00:00Z').minusPeriod(period, berlin),
        start,
      );
      expect(
        start.plusPeriod(DateTimePeriod(nanoseconds: -1), berlin),
        Instant.parse('2026-03-28T11:59:59.999999999Z'),
      );
    });

    test('keeps the offset it had where a day is repeated', () {
      final autumn = Instant.parse('2026-10-24T00:30:00Z');

      expect(
        autumn.plus(1, DateTimeUnit.day, timeZone: berlin),
        Instant.parse('2026-10-25T00:30:00Z'),
      );
    });
  });

  group('distances', () {
    final from = Instant.parse('2026-01-31T10:00:00Z');

    test('counts exact units', () {
      final to = Instant.parse('2026-01-31T12:30:00.5Z');

      expect(from.until(to, DateTimeUnit.hour), 2);
      expect(from.until(to, DateTimeUnit.minute), 150);
      expect(from.until(to, DateTimeUnit.millisecond), 9000500);
      expect(to.until(from, DateTimeUnit.second), -9000);
      expect(
        Instant.fromEpochSeconds(
          1,
          1,
        ).until(Instant.epoch, DateTimeUnit.second),
        -1,
      );
      expect(
        Instant.epoch.until(
          Instant.fromEpochSeconds(-1, 999999999),
          DateTimeUnit.nanosecond,
        ),
        -1,
      );
    });

    test('counts calendar units on the clocks of a zone', () {
      final to = Instant.parse('2026-03-31T09:00:00Z');

      expect(from.daysUntil(to, berlin), 59);
      expect(from.monthsUntil(to, berlin), 2);
      expect(from.yearsUntil(to, berlin), 0);
      expect(to.monthsUntil(from, berlin), -2);
      expect(from.until(to, DateTimeUnit.week, timeZone: berlin), 8);
      expect(from.until(to, DateTimeUnit.quarter, timeZone: berlin), 0);
      expect(() => from.until(to, DateTimeUnit.day), throwsArgumentError);
    });

    test('measures periods with one sign', () {
      final to = Instant.parse('2026-03-02T12:30:00Z');

      expect(
        from.periodUntil(to, TimeZone.utc),
        DateTimePeriod(months: 1, days: 2, hours: 2, minutes: 30),
      );
      expect(
        to.periodUntil(from, TimeZone.utc),
        DateTimePeriod(months: -1, days: -2, hours: -2, minutes: -30),
      );
    });

    test('reads the clocks and offsets of a zone', () {
      expect(
        from.toLocalDateTime(berlin),
        LocalDateTime.of(2026, 1, 31, 11, 0),
      );
      expect(from.offsetIn(berlin), UtcOffset(hours: 1));
    });
  });

  group('order and text', () {
    test('orders and compares', () {
      final early = Instant.fromEpochSeconds(5);
      final late = Instant.fromEpochSeconds(5, 1);

      expect(early.isBefore(late), isTrue);
      expect(late.isAfter(early), isTrue);
      expect(early.compareTo(Instant.fromEpochSeconds(5)), 0);
      expect(Instant.fromEpochSeconds(6).compareTo(late), isPositive);
      expect(early.hashCode, Instant.fromEpochSeconds(5).hashCode);
      expect(early == late, isFalse);
    });

    test('writes and reads ISO 8601 text', () {
      expect(Instant.epoch.toString(), '1970-01-01T00:00:00Z');
      expect(
        Instant.fromEpochSeconds(0, 1000000).toString(),
        '1970-01-01T00:00:00.001Z',
      );
      expect(
        Instant.parse('2026-10-09T14:30+02:00'),
        Instant.parse('2026-10-09T12:30:00Z'),
      );
      expect(
        Instant.parse('2026-10-09T12:30:00.123456789z').nanosecondsOfSecond,
        123456789,
      );
      expect(
        Instant.parse('2026-10-09T10:30:00-0200'),
        Instant.parse('2026-10-09T12:30:00Z'),
      );
      expect(() => Instant.parse('2026-10-09T12:30'), throwsFormatException);
      expect(() => Instant.parse('yesterday'), throwsFormatException);
    });
  });
}
