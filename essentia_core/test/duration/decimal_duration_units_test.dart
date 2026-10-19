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
import 'package:essentia_core/src/duration/decimal_duration_units.dart';
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
