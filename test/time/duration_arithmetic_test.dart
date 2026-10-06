/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/time/duration_arithmetic.dart';
import 'package:essentia/src/time/duration_components.dart';
import 'package:test/test.dart';

/// Covers dividing durations, `toComponents` and `toIsoString`.
void main() {
  test('divides one duration by another', () {
    const duration = Duration(minutes: 3);

    final double ratio = duration / const Duration(seconds: 40);

    expect(ratio, 4.5);
  });

  test('splits into its components', () {
    const duration = Duration(
      days: 1,
      hours: 2,
      minutes: 3,
      seconds: 4,
      microseconds: 5,
    );

    final DurationComponents components = duration.toComponents();

    expect(components, (
      days: 1,
      hours: 2,
      minutes: 3,
      seconds: 4,
      microseconds: 5,
    ));
  });

  test('keeps the sign in every component of a negative duration', () {
    const duration = Duration(hours: -1, minutes: -30);

    final DurationComponents components = duration.toComponents();

    expect(components, (
      days: 0,
      hours: -1,
      minutes: -30,
      seconds: 0,
      microseconds: 0,
    ));
  });

  test('formats hours and minutes as ISO 8601', () {
    const duration = Duration(hours: 1, minutes: 30);

    final String iso = duration.toIsoString();

    expect(iso, 'PT1H30M');
  });

  test('formats days as hours the way Kotlin does', () {
    const duration = Duration(days: 1, hours: 12);

    final String iso = duration.toIsoString();

    expect(iso, 'PT36H');
  });

  test('keeps the minutes between hours and seconds', () {
    const duration = Duration(hours: 2, seconds: 5);

    final String iso = duration.toIsoString();

    expect(iso, 'PT2H0M5S');
  });

  test('formats a fraction of a second without trailing zeros', () {
    const duration = Duration(seconds: 1, milliseconds: 500);

    final String iso = duration.toIsoString();

    expect(iso, 'PT1.5S');
  });

  test('formats a single microsecond', () {
    const duration = Duration(microseconds: 1);

    final String iso = duration.toIsoString();

    expect(iso, 'PT0.000001S');
  });

  test('formats zero as zero seconds', () {
    const Duration duration = Duration.zero;

    final String iso = duration.toIsoString();

    expect(iso, 'PT0S');
  });

  test('formats a negative duration with a leading sign', () {
    const duration = Duration(minutes: -5);

    final String iso = duration.toIsoString();

    expect(iso, '-PT5M');
  });
}
