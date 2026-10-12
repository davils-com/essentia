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

/// A format of every field of a date and time, separated by dashes.
final DateTimeFormat<LocalDateTime> _everyField = localDateTimeFormat(
  (it) => it
    ..year()
    ..char('-')
    ..monthNumber()
    ..char('-')
    ..day()
    ..chars(' at ')
    ..hour()
    ..char(':')
    ..minute()
    ..char(':')
    ..second()
    ..char('.')
    ..secondFraction(9),
);

/// Writes the fraction of [time] with [length] digits.
///
/// Returns the digits.
String _fraction(LocalTime time, int length) =>
    localTimeFormat((it) => it.secondFraction(length)).format(time);

/// Covers the builders of date and time formats: the fields, their widths,
/// literals, nested formats and the checks of their arguments.
void main() {
  group('a date and time format', () {
    test('writes every field at its full width', () {
      expect(
        _everyField.format(LocalDateTime.of(2026, 3, 7, 9, 5, 4, 12)),
        '2026-03-07 at 09:05:04.000000012',
      );
    });

    test('writes midnight with every zero', () {
      expect(
        _everyField.format(
          LocalDateTime(LocalDate(2026, 1, 1), LocalTime.midnight),
        ),
        '2026-01-01 at 00:00:00.000000000',
      );
    });

    test('writes the last moment of a day', () {
      expect(
        _everyField.format(
          LocalDateTime(LocalDate(1999, 12, 31), LocalTime.max),
        ),
        '1999-12-31 at 23:59:59.999999999',
      );
    });

    test('writes year 0 with four zeros', () {
      expect(
        _everyField.format(LocalDateTime.of(0, 1, 1, 0, 0)),
        '0000-01-01 at 00:00:00.000000000',
      );
    });

    test('writes a year before 0 with a minus sign', () {
      expect(
        _everyField.format(LocalDateTime.of(-1, 2, 3, 4, 5)),
        startsWith('-0001-02-03'),
      );
      expect(
        _everyField.format(LocalDateTime.of(-44, 3, 15, 12, 0)),
        startsWith('-0044-03-15'),
      );
      expect(
        _everyField.format(LocalDateTime.of(-12345, 1, 1, 0, 0)),
        startsWith('-12345-01-01'),
      );
    });

    test('writes a year after 9999 with a plus sign', () {
      expect(
        _everyField.format(LocalDateTime.of(9999, 12, 31, 0, 0)),
        startsWith('9999-12-31'),
      );
      expect(
        _everyField.format(LocalDateTime.of(10000, 1, 1, 0, 0)),
        startsWith('+10000-01-01'),
      );
    });

    test('writes into a sink it is given', () {
      final buffer = StringBuffer('logged ');

      _everyField.formatTo(buffer, LocalDateTime.of(2026, 10, 10, 8, 30));

      expect(buffer.toString(), 'logged 2026-10-10 at 08:30:00.000000000');
    });

    test('writes nothing when it has no field', () {
      expect(
        localDateTimeFormat((it) {}).format(LocalDateTime.of(2026, 1, 1, 0, 0)),
        '',
      );
    });

    test('nests a format of the date and one of the time', () {
      final DateTimeFormat<LocalDate> date = localDateFormat(
        (it) => it
          ..day()
          ..char('.')
          ..monthNumber()
          ..char('.')
          ..year(),
      );
      final DateTimeFormat<LocalTime> time = localTimeFormat(
        (it) => it
          ..hour()
          ..char('h')
          ..minute(),
      );

      final DateTimeFormat<LocalDateTime> format = localDateTimeFormat(
        (it) => it
          ..date(date)
          ..chars(', ')
          ..time(time),
      );

      expect(
        format.format(LocalDateTime.of(2026, 10, 10, 7, 45)),
        '10.10.2026, 07h45',
      );
    });

    test('is not changed by later calls on its builder', () {
      final builder = DateTimeFormatBuilder()..hour();
      final DateTimeFormat<LocalDateTime> format = builder.build();

      builder.minute();

      expect(format.format(LocalDateTime.of(2026, 1, 1, 13, 14)), '13');
      expect(
        builder.build().format(LocalDateTime.of(2026, 1, 1, 13, 14)),
        '1314',
      );
    });
  });

  group('a date format', () {
    test('writes the fields of a date', () {
      final DateTimeFormat<LocalDate> format = localDateFormat(
        (it) => it
          ..year()
          ..monthNumber()
          ..day(),
      );

      expect(format.format(LocalDate(2026, 2, 9)), '20260209');
    });

    test('nests another format of a date', () {
      final DateTimeFormat<LocalDate> format = localDateFormat(
        (it) => it
          ..chars('on ')
          ..date(DateTimeFormats.isoDate),
      );

      expect(format.format(LocalDate(2026, 2, 9)), 'on 2026-02-09');
    });
  });

  group('a time format', () {
    test('writes the fields of a time of day', () {
      final DateTimeFormat<LocalTime> format = localTimeFormat(
        (it) => it
          ..hour()
          ..minute()
          ..second(),
      );

      expect(format.format(LocalTime(7, 8, 9)), '070809');
    });

    test('nests another format of a time of day', () {
      final DateTimeFormat<LocalTime> format = localTimeFormat(
        (it) => it
          ..char('[')
          ..time(DateTimeFormats.time)
          ..char(']'),
      );

      expect(format.format(LocalTime(7, 8, 9)), '[07:08:09.000]');
    });
  });

  group('the fraction of a second', () {
    test('is cut off at its length, never rounded', () {
      final time = LocalTime(23, 59, 59, 999999999);

      expect(
        <String>[
          for (var length = 1; length <= 9; length++) _fraction(time, length),
        ],
        <String>[
          '9',
          '99',
          '999',
          '9999',
          '99999',
          '999999',
          '9999999',
          '99999999',
          '999999999',
        ],
      );
    });

    test('keeps its leading zeros', () {
      final time = LocalTime(0, 0, 0, 1234567);

      expect(_fraction(time, 1), '0');
      expect(_fraction(time, 3), '001');
      expect(_fraction(time, 6), '001234');
      expect(_fraction(time, 9), '001234567');
    });

    test('is all zeros for a whole second', () {
      expect(_fraction(LocalTime(12, 0), 4), '0000');
    });

    test('refuses a length outside 1 to 9', () {
      expect(() => TimeFormatBuilder().secondFraction(0), throwsRangeError);
      expect(() => TimeFormatBuilder().secondFraction(10), throwsRangeError);
      expect(
        () => DateTimeFormatBuilder().secondFraction(-1),
        throwsRangeError,
      );
    });
  });

  group('a literal', () {
    test('of one character takes a character outside the basic plane', () {
      final DateTimeFormat<LocalTime> format = localTimeFormat(
        (it) => it
          ..char('\u{1F552}')
          ..hour(),
      );

      expect(format.format(LocalTime(3, 0)), '\u{1F552}03');
    });

    test('of one character refuses none or more than one', () {
      expect(() => DateTimeFormatBuilder().char(''), throwsArgumentError);
      expect(() => DateFormatBuilder().char('ab'), throwsArgumentError);
      expect(() => TimeFormatBuilder().char('::'), throwsArgumentError);
    });

    test('of text writes it as it is, empty text included', () {
      final DateTimeFormat<LocalDate> format = localDateFormat(
        (it) => it
          ..chars('')
          ..chars("year 'y' ")
          ..year(),
      );

      expect(format.format(LocalDate(2026, 1, 1)), "year 'y' 2026");
    });
  });
}
