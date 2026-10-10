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

/// A moment with every field distinct.
final _moment = LocalDateTime.of(2026, 3, 7, 9, 5, 4, 123456789);

/// Covers `DateTimeFormats` and the formatting of an `Instant`.
void main() {
  group('the common formats', () {
    test('write a date as ISO 8601 does', () {
      expect(DateTimeFormats.isoDate.format(_moment.date), '2026-03-07');
    });

    test('write a time to the millisecond, cut off', () {
      expect(DateTimeFormats.time.format(_moment.time), '09:05:04.123');
    });

    test('write a date and time separated by a space', () {
      expect(
        DateTimeFormats.dateTime.format(_moment),
        '2026-03-07 09:05:04.123',
      );
    });

    test('write a local date and time as ISO 8601 does', () {
      expect(
        DateTimeFormats.isoLocal.format(_moment),
        '2026-03-07T09:05:04.123',
      );
    });

    test('write a date and time in UTC with a Z', () {
      expect(
        DateTimeFormats.isoInstantUtc.format(_moment),
        '2026-03-07T09:05:04.123Z',
      );
    });

    test('write the seconds and fraction that toString leaves out', () {
      final midnight = LocalDateTime(LocalDate(2026, 1, 1), LocalTime.midnight);

      expect(midnight.toString(), '2026-01-01T00:00');
      expect(
        DateTimeFormats.isoLocal.format(midnight),
        '2026-01-01T00:00:00.000',
      );
      expect(DateTimeFormats.time.format(LocalTime.midnight), '00:00:00.000');
    });

    test('agree with the pattern they are documented with', () {
      final pairs = <(DateTimeFormat<LocalDateTime>, String)>[
        (DateTimeFormats.dateTime, 'yyyy-MM-dd HH:mm:ss.SSS'),
        (DateTimeFormats.isoLocal, "yyyy-MM-dd'T'HH:mm:ss.SSS"),
        (DateTimeFormats.isoInstantUtc, "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"),
      ];
      final moments = <LocalDateTime>[
        _moment,
        LocalDateTime.of(0, 1, 1, 0, 0),
        LocalDateTime.of(-250, 6, 30, 23, 59, 59, 999999999),
        LocalDateTime.of(10000, 12, 31, 12, 0, 0, 1000000),
      ];

      for (final (format, pattern) in pairs) {
        for (final moment in moments) {
          expect(
            format.format(moment),
            localDateTimePattern(pattern).format(moment),
            reason: '$pattern $moment',
          );
        }
      }
    });

    test('are constants', () {
      const DateTimeFormat<LocalDateTime> format =
          DateTimeFormats.isoInstantUtc;

      expect(identical(format, DateTimeFormats.isoInstantUtc), isTrue);
    });
  });

  group('an instant', () {
    final instant = Instant.parse('2026-10-10T08:15:30.5Z');

    test('is written in UTC unless a zone is given', () {
      expect(
        instant.format(DateTimeFormats.isoInstantUtc),
        '2026-10-10T08:15:30.500Z',
      );
      expect(
        instant.format(DateTimeFormats.dateTime),
        '2026-10-10 08:15:30.500',
      );
    });

    test('is written as the clock of the zone it is given shows it', () {
      expect(
        instant.format(DateTimeFormats.dateTime, TimeZone.of('Europe/Berlin')),
        '2026-10-10 10:15:30.500',
      );
      expect(
        instant.format(
          DateTimeFormats.isoLocal,
          TimeZone.of('America/New_York'),
        ),
        '2026-10-10T04:15:30.500',
      );
    });

    test('before 1970 is written with the right fraction', () {
      final before = Instant.parse('1969-12-31T23:59:59.999Z');

      expect(
        before.format(DateTimeFormats.isoInstantUtc),
        '1969-12-31T23:59:59.999Z',
      );
    });

    test('at the epoch is written with every zero', () {
      expect(
        Instant.fromEpochSeconds(0).format(DateTimeFormats.isoInstantUtc),
        '1970-01-01T00:00:00.000Z',
      );
    });
  });
}
