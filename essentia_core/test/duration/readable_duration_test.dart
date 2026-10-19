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

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_core/src/duration/readable_duration.dart';
import 'package:test/test.dart';

/// Durations and the readable text `toReadableString` writes for them.
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
