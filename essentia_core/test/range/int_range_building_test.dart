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

import 'package:essentia_core/src/range/int_progression.dart';
import 'package:essentia_core/src/range/int_range_building.dart';
import 'package:test/test.dart';

/// Covers building integer ranges with `rangeTo`, `until` and `downTo`.
void main() {
  test('builds a range up to and including its end', () {
    const start = 1;

    final IntRange range = start.rangeTo(3);

    expect(range.toList(), <int>[1, 2, 3]);
  });

  test('builds a range that stops before its end', () {
    const start = 1;

    final IntRange range = start.until(3);

    expect(range.toList(), <int>[1, 2]);
  });

  test('builds an empty range until its own start', () {
    const start = 3;

    final IntRange range = start.until(3);

    expect(range.isEmpty, isTrue);
  });

  test('builds a progression counting down', () {
    const start = 3;

    final IntProgression progression = start.downTo(1);

    expect(progression.toList(), <int>[3, 2, 1]);
  });
}
