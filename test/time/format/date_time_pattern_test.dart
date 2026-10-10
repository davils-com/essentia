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

/// Writes [_moment] with the format of [pattern].
///
/// Returns the text.
String _write(String pattern) => localDateTimePattern(pattern).format(_moment);

/// Covers `localDateTimePattern`: its letters, quoted and plain literals,
/// and the patterns it refuses.
void main() {
  test('writes every letter it knows', () {
    expect(_write('yyyy-MM-dd HH:mm:ss.SSS'), '2026-03-07 09:05:04.123');
    expect(_write('ddMMyyyyHHmmss'), '07032026090504');
  });

  test('writes one to nine digits of the fraction', () {
    expect(
      <String>[
        for (var length = 1; length <= 9; length++) _write('S' * length),
      ],
      <String>[
        '1',
        '12',
        '123',
        '1234',
        '12345',
        '123456',
        '1234567',
        '12345678',
        '123456789',
      ],
    );
  });

  test('writes quoted text as it is', () {
    expect(_write("yyyy-MM-dd'T'HH:mm"), '2026-03-07T09:05');
    expect(_write("'day' dd 'of' MM"), 'day 07 of 03');
    expect(_write("HH'h'"), '09h');
  });

  test('writes two quotes as one, inside quotes and outside', () {
    expect(_write("HH''mm"), "09'05");
    expect(_write("'o''clock' HH"), "o'clock 09");
    expect(_write("''"), "'");
    expect(_write("''''"), "''");
  });

  test('writes empty quotes as nothing', () {
    expect(_write("HH''''mm"), "09''05");
    expect(_write("HH'' ''mm"), "09' '05");
  });

  test('writes every other character as it is', () {
    expect(_write('[dd/MM/yyyy, HH:mm]'), '[07/03/2026, 09:05]');
    expect(_write('HH\u{1F552}mm ä'), '09\u{1F552}05 ä');
    expect(_write(''), '');
  });

  test('writes the full width of a year beyond four digits', () {
    final DateTimeFormat<LocalDateTime> format = localDateTimePattern('yyyy');

    expect(format.format(LocalDateTime.of(-7, 1, 1, 0, 0)), '-0007');
    expect(format.format(LocalDateTime.of(12026, 1, 1, 0, 0)), '+12026');
  });

  test('refuses a letter it does not know', () {
    expect(
      () => localDateTimePattern('yyyy-MM-ddTHH:mm'),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains("'T' at index 10"),
        ),
      ),
    );
    expect(() => localDateTimePattern('EEE'), throwsArgumentError);
    expect(() => localDateTimePattern('hh:mm a'), throwsArgumentError);
  });

  test('refuses a known letter at a width it does not support', () {
    for (final pattern in <String>[
      'yy',
      'yyyyy',
      'M',
      'MMM',
      'd',
      'H',
      'mmm',
      's',
      'SSSSSSSSSS',
    ]) {
      expect(
        () => localDateTimePattern(pattern),
        throwsArgumentError,
        reason: pattern,
      );
    }
  });

  test('refuses a quote that is not closed', () {
    expect(
      () => localDateTimePattern("HH 'o''clock"),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('index 3'),
        ),
      ),
    );
    expect(() => localDateTimePattern("'"), throwsArgumentError);
  });
}
