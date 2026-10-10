/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/time/readable_duration.dart';
import 'package:test/test.dart';

/// Durations and the text Kotlin's `Duration.toString()` writes for them.
final _rendered = <Duration, String>{
  Duration.zero: '0s',
  const Duration(seconds: 30): '30s',
  const Duration(hours: 1, minutes: 30): '1h 30m',
  const Duration(days: 1, seconds: 5): '1d 0h 0m 5s',
  const Duration(days: 2): '2d',
  const Duration(days: 1, hours: 3): '1d 3h',
  const Duration(hours: 2, seconds: 1): '2h 0m 1s',
  const Duration(minutes: 1, milliseconds: 500): '1m 0.5s',
  const Duration(seconds: 2, microseconds: 1): '2.000001s',
  const Duration(milliseconds: 250): '250ms',
  const Duration(microseconds: 1500): '1.5ms',
  const Duration(microseconds: 1001): '1.001ms',
  const Duration(microseconds: 42): '42us',
  const Duration(seconds: -30): '-30s',
  const Duration(minutes: -1, seconds: -30): '-(1m 30s)',
  const Duration(microseconds: -42): '-42us',
};

/// Covers the readable form of a duration.
void main() {
  for (final MapEntry<Duration, String>(:key, :value) in _rendered.entries) {
    test('renders $value', () {
      final String text = key.toReadableString();

      expect(text, value);
    });
  }
}
