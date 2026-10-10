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

/// Covers times of day: validation, the counts since midnight, ordering
/// and ISO 8601 text.
void main() {
  test('refuses parts that do not exist', () {
    expect(() => LocalTime(24, 0), throwsArgumentError);
    expect(() => LocalTime(-1, 0), throwsArgumentError);
    expect(() => LocalTime(12, 60), throwsArgumentError);
    expect(() => LocalTime(12, 0, 60), throwsArgumentError);
    expect(() => LocalTime(12, 0, 0, 1000000000), throwsArgumentError);
    expect(() => LocalTime.fromSecondOfDay(86400), throwsArgumentError);
    expect(() => LocalTime.fromMillisecondOfDay(-1), throwsArgumentError);
    expect(
      () => LocalTime.fromNanosecondOfDay(86400000000000),
      throwsArgumentError,
    );
  });

  test('counts from midnight both ways', () {
    final time = LocalTime(13, 45, 30, 250000000);

    expect(time.toSecondOfDay(), 49530);
    expect(time.toMillisecondOfDay(), 49530250);
    expect(time.toNanosecondOfDay(), 49530250000000);
    expect(LocalTime.fromSecondOfDay(49530), LocalTime(13, 45, 30));
    expect(LocalTime.fromMillisecondOfDay(49530250), time);
    expect(LocalTime.fromNanosecondOfDay(49530250000000), time);
    expect(LocalTime.max.toNanosecondOfDay(), 86399999999999);
    expect(LocalTime.midnight.toSecondOfDay(), 0);
    expect(LocalTime.noon, LocalTime(12, 0));
  });

  test('reads the time of a DateTime and joins a date', () {
    expect(
      LocalTime.fromDateTime(DateTime.utc(2026, 1, 1, 9, 5, 7, 8, 9)),
      LocalTime(9, 5, 7, 8009000),
    );
    expect(
      LocalTime(9, 30).atDate(LocalDate(2026, 10, 9)),
      LocalDateTime.of(2026, 10, 9, 9, 30),
    );
  });

  test('orders and compares', () {
    final early = LocalTime(8, 0);
    final late = LocalTime(8, 0, 0, 1);

    expect(early.isBefore(late), isTrue);
    expect(late.isAfter(early), isTrue);
    expect(early.compareTo(LocalTime(8, 0)), 0);
    expect(early, LocalTime(8, 0));
    expect(early.hashCode, LocalTime(8, 0).hashCode);
    expect(early == late, isFalse);
  });

  test('writes and reads ISO 8601 text', () {
    expect(LocalTime(9, 5).toString(), '09:05');
    expect(LocalTime(9, 5, 7).toString(), '09:05:07');
    expect(LocalTime(9, 5, 7, 500000000).toString(), '09:05:07.500');
    expect(LocalTime(9, 5, 0, 1000).toString(), '09:05:00.000001');
    expect(LocalTime(9, 5, 0, 1).toString(), '09:05:00.000000001');
    expect(LocalTime.parse('09:05'), LocalTime(9, 5));
    expect(LocalTime.parse('23:59:59.5'), LocalTime(23, 59, 59, 500000000));
    expect(LocalTime.parse('00:00:01,000000001'), LocalTime(0, 0, 1, 1));
    expect(() => LocalTime.parse('24:00'), throwsFormatException);
    expect(() => LocalTime.parse('9:05'), throwsFormatException);
    expect(() => LocalTime.parse('09:60'), throwsFormatException);
  });
}
