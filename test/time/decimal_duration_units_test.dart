/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/time/decimal_duration_units.dart';
import 'package:test/test.dart';

/// Covers the decimal duration units such as `1.5.seconds`.
void main() {
  test('expresses fractional days', () {
    final Duration duration = 0.5.days;

    expect(duration, const Duration(hours: 12));
  });

  test('expresses fractional hours', () {
    final Duration duration = 1.5.hours;

    expect(duration, const Duration(minutes: 90));
  });

  test('expresses fractional minutes', () {
    final Duration duration = 0.25.minutes;

    expect(duration, const Duration(seconds: 15));
  });

  test('expresses fractional seconds', () {
    final Duration duration = 1.5.seconds;

    expect(duration, const Duration(milliseconds: 1500));
  });

  test('expresses fractional milliseconds', () {
    final Duration duration = 2.5.milliseconds;

    expect(duration, const Duration(microseconds: 2500));
  });

  test('rounds fractional microseconds to whole ones', () {
    final Duration duration = 2.6.microseconds;

    expect(duration, const Duration(microseconds: 3));
  });
}
