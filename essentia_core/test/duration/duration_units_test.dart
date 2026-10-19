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
import 'package:essentia_core/src/duration/duration_units.dart';
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
