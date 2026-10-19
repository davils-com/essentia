/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:math';

import 'package:essentia_core/essentia_core.dart';
import 'package:test/test.dart';

/// ISO-8601 texts and the duration each one means.
const _readable = <String, Duration>{
  'PT30S': Duration(seconds: 30),
  'PT1H30M': Duration(hours: 1, minutes: 30),
  'P1DT2H': Duration(days: 1, hours: 2),
  'P2D': Duration(days: 2),
  'PT0S': Duration.zero,
  'PT0.5S': Duration(milliseconds: 500),
  'PT0.000001S': Duration(microseconds: 1),
  'PT1.5H': Duration(hours: 1, minutes: 30),
  'pt15m': Duration(minutes: 15),
  '-PT1H': Duration(hours: -1),
};

/// Texts that are not ISO-8601 durations.
const _refused = <String>[
  '',
  'P',
  'PT',
  'P1DT',
  '30s',
  '1h 30m',
  'P1Y',
  'P1M',
  'P1W',
  'PT1H30',
  '--PT1H',
  '+PT1H',
  ' PT1H',
  'PT-1H',
];

/// Covers reading ISO-8601 durations and the round trip with
/// `toIsoString`.
void main() {
  for (final MapEntry<String, Duration>(:key, :value) in _readable.entries) {
    test('reads $key', () {
      final Duration duration = key.toIsoDuration();

      expect(duration, value);
    });
  }

  for (final String text in _refused) {
    test('refuses "$text"', () {
      final Duration? duration = text.toIsoDurationOrNull();

      expect(duration, isNull);
    });
  }

  test('a refusal does not quote the text', () {
    const text = 'secret-token';

    expect(
      text.toIsoDuration,
      throwsA(
        isA<FormatException>().having(
          (failure) => failure.message,
          'message',
          isNot(contains(text)),
        ),
      ),
    );
  });

  test('reads back what toIsoString renders', () {
    final random = Random(9562);
    const span = 0x100000000;
    for (var round = 0; round < 1000; round++) {
      final int microseconds = random.nextInt(span) * 256 + random.nextInt(256);
      final duration = Duration(
        microseconds: random.nextBool() ? microseconds : -microseconds,
      );

      final Duration read = duration.toIsoString().toIsoDuration();

      expect(read, duration, reason: duration.toIsoString());
    }
  });
}
