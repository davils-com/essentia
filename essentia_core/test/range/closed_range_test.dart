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

import 'package:essentia_core/src/range/closed_range.dart';
import 'package:test/test.dart';

/// Covers the closed range of comparable values.
void main() {
  test('contains both of its ends', () {
    const range = ClosedRange<String>('b', 'd');

    final bool contained = range.contains('b') && range.contains('d');

    expect(contained, isTrue);
  });

  test('excludes a value beyond its end', () {
    const range = ClosedRange<String>('b', 'd');

    final bool contained = range.contains('e');

    expect(contained, isFalse);
  });

  test('excludes a value before its start', () {
    const range = ClosedRange<String>('b', 'd');

    final bool contained = range.contains('a');

    expect(contained, isFalse);
  });

  test('is empty when its start exceeds its end', () {
    const range = ClosedRange<num>(3, 1);

    final bool empty = range.isEmpty;

    expect(empty, isTrue);
  });

  test('is not empty when it holds a single value', () {
    const range = ClosedRange<num>(1, 1);

    final bool empty = range.isEmpty;

    expect(empty, isFalse);
  });

  test('equals a range with the same ends', () {
    const range = ClosedRange<num>(1, 3);

    final equal = range == const ClosedRange<num>(1, 3);

    expect(equal, isTrue);
  });

  test('differs from a range with another end', () {
    const range = ClosedRange<num>(1, 3);

    final equal = range == const ClosedRange<num>(1, 4);

    expect(equal, isFalse);
  });

  test('shares the hash code of an equal range', () {
    const range = ClosedRange<num>(1, 3);

    final hash = range.hashCode;

    expect(hash, const ClosedRange<num>(1, 3).hashCode);
  });

  test('describes itself with both ends', () {
    const range = ClosedRange<num>(1, 3);

    final description = range.toString();

    expect(description, '1..3');
  });
}
