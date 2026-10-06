/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/time/duration_units.dart';
import 'package:test/test.dart';

/// Covers the whole number duration units such as `5.seconds`.
void main() {
  test('expresses days', () {
    final Duration duration = 2.days;

    expect(duration, const Duration(days: 2));
  });

  test('expresses hours', () {
    final Duration duration = 3.hours;

    expect(duration, const Duration(hours: 3));
  });

  test('expresses minutes', () {
    final Duration duration = 4.minutes;

    expect(duration, const Duration(minutes: 4));
  });

  test('expresses seconds', () {
    final Duration duration = 5.seconds;

    expect(duration, const Duration(seconds: 5));
  });

  test('expresses milliseconds', () {
    final Duration duration = 250.milliseconds;

    expect(duration, const Duration(milliseconds: 250));
  });

  test('expresses microseconds', () {
    final Duration duration = 7.microseconds;

    expect(duration, const Duration(microseconds: 7));
  });
}
