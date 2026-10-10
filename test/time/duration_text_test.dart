/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

import 'package:essentia/src/time/duration_text.dart';
import 'package:essentia/src/time/readable_duration.dart';
import 'package:test/test.dart';

/// Texts in either form and the duration each one means.
const _read = <String, Duration>{
  '30s': Duration(seconds: 30),
  '1h 30m': Duration(hours: 1, minutes: 30),
  '1h30m': Duration(hours: 1, minutes: 30),
  '2d': Duration(days: 2),
  '250ms': Duration(milliseconds: 250),
  '1.5ms': Duration(microseconds: 1500),
  '42us': Duration(microseconds: 42),
  '1500ns': Duration(microseconds: 2),
  '1.5h': Duration(hours: 1, minutes: 30),
  ' 5 m ': Duration(minutes: 5),
  '-30s': Duration(seconds: -30),
  '-(1m 30s)': Duration(minutes: -1, seconds: -30),
  '- ( 1m 30s )': Duration(minutes: -1, seconds: -30),
  'PT30S': Duration(seconds: 30),
  '-PT1H': Duration(hours: -1),
};

/// Texts that are neither form.
const _refused = <String>[
  '',
  ' ',
  'soon',
  '30',
  '30x',
  '30m 1h',
  '1h 1h',
  '--1h',
  '-(-1h)',
  '(1h 30m)',
  '1h, 30m',
  'P1Y',
];

/// Covers reading both forms of a duration.
void main() {
  for (final MapEntry<String, Duration>(:key, :value) in _read.entries) {
    test('reads "$key"', () {
      final Duration duration = key.toDuration();

      expect(duration, value);
    });
  }

  for (final String text in _refused) {
    test('refuses "$text"', () {
      final Duration? duration = text.toDurationOrNull();

      expect(duration, isNull);
    });
  }

  test('a refusal does not quote the text', () {
    const text = 'secret-token';

    expect(
      text.toDuration,
      throwsA(
        isA<FormatException>().having(
          (failure) => failure.message,
          'message',
          isNot(contains(text)),
        ),
      ),
    );
  });

  test('reads back what toReadableString renders', () {
    final random = Random(4711);
    const span = 0x100000000;
    for (var round = 0; round < 1000; round++) {
      final int microseconds = random.nextInt(span) * 256 + random.nextInt(256);
      final duration = Duration(
        microseconds: random.nextBool() ? microseconds : -microseconds,
      );

      final Duration read = duration.toReadableString().toDuration();

      expect(read, duration, reason: duration.toReadableString());
    }
  });
}
