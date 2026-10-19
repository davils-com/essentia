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
import 'package:test/test.dart';

/// Covers the integer progression: its elements, length, membership,
/// direction, equality and description.
void main() {
  test('yields every step from its start', () {
    final progression = IntProgression(1, 10, step: 3);

    final List<int> values = progression.toList();

    expect(values, <int>[1, 4, 7, 10]);
  });

  test('ends at the last element the step reaches', () {
    final progression = IntProgression(1, 9, step: 3);

    final int end = progression.endInclusive;

    expect(end, 7);
  });

  test('ends at the last element a negative step reaches', () {
    final progression = IntProgression(10, 1, step: -4);

    final List<int> values = progression.toList();

    expect(values, <int>[10, 6, 2]);
  });

  test('ends at the start of an empty descending progression', () {
    final progression = IntProgression(1, 5, step: -2);

    final int end = progression.endInclusive;

    expect(end, 5);
  });

  test('refuses a step of zero', () {
    IntProgression build() => IntProgression(1, 5, step: 0);

    expect(build, throwsArgumentError);
  });

  test('is empty when an ascending start lies beyond its end', () {
    final progression = IntProgression(5, 1);

    final bool empty = progression.isEmpty;

    expect(empty, isTrue);
  });

  test('is empty when a descending start lies before its end', () {
    final progression = IntProgression(1, 5, step: -1);

    final bool empty = progression.isEmpty;

    expect(empty, isTrue);
  });

  test('counts its elements without iterating', () {
    final progression = IntProgression(0, 100, step: 7);

    final int count = progression.length;

    expect(count, 15);
  });

  test('counts no elements when empty', () {
    final progression = IntProgression(5, 1);

    final int count = progression.length;

    expect(count, 0);
  });

  test('reads its first element', () {
    final progression = IntProgression(3, 9, step: 2);

    final int value = progression.first;

    expect(value, 3);
  });

  test('refuses the first element when empty', () {
    final progression = IntProgression(5, 1);

    int read() => progression.first;

    expect(read, throwsStateError);
  });

  test('reads its last element', () {
    final progression = IntProgression(3, 10, step: 2);

    final int value = progression.last;

    expect(value, 9);
  });

  test('refuses the last element when empty', () {
    final progression = IntProgression(5, 1);

    int read() => progression.last;

    expect(read, throwsStateError);
  });

  test('contains a value on its step', () {
    final progression = IntProgression(10, 1, step: -3);

    final bool contained = progression.contains(4);

    expect(contained, isTrue);
  });

  test('excludes a value between its steps', () {
    final progression = IntProgression(1, 10, step: 3);

    final bool contained = progression.contains(5);

    expect(contained, isFalse);
  });

  test('excludes a value beyond its end', () {
    final progression = IntProgression(1, 10, step: 3);

    final bool contained = progression.contains(13);

    expect(contained, isFalse);
  });

  test('excludes a value before its start', () {
    final progression = IntProgression(1, 10, step: 3);

    final bool contained = progression.contains(-2);

    expect(contained, isFalse);
  });

  test('excludes everything when empty', () {
    final progression = IntProgression(5, 1);

    final bool contained = progression.contains(3);

    expect(contained, isFalse);
  });

  test('excludes a value that is not an integer', () {
    final progression = IntProgression(1, 10);
    const Object text = '3';

    final bool contained = progression.contains(text);

    expect(contained, isFalse);
  });

  test('reads an element by its index', () {
    final progression = IntProgression(1, 10, step: 3);

    final int value = progression.elementAt(2);

    expect(value, 7);
  });

  test('refuses an index beyond its length', () {
    final progression = IntProgression(1, 10, step: 3);

    int read() => progression.elementAt(4);

    expect(read, throwsRangeError);
  });

  test('reverses its direction', () {
    final progression = IntProgression(1, 9, step: 3);

    final List<int> values = progression.reversed().toList();

    expect(values, <int>[7, 4, 1]);
  });

  test('steps by a larger distance in its own direction', () {
    final progression = IntProgression(10, 0, step: -1);

    final List<int> values = progression.stepBy(4).toList();

    expect(values, <int>[10, 6, 2]);
  });

  test('steps by a larger distance upwards', () {
    final progression = IntProgression(0, 10);

    final List<int> values = progression.stepBy(5).toList();

    expect(values, <int>[0, 5, 10]);
  });

  test('refuses a step that is not positive', () {
    final progression = IntProgression(0, 10);

    IntProgression step() => progression.stepBy(0);

    expect(step, throwsArgumentError);
  });

  test('equals a progression with the same elements and step', () {
    final progression = IntProgression(1, 9, step: 3);

    final equal = progression == IntProgression(1, 7, step: 3);

    expect(equal, isTrue);
  });

  test('differs from a progression with another step', () {
    final progression = IntProgression(1, 7, step: 3);

    final equal = progression == IntProgression(1, 7, step: 6);

    expect(equal, isFalse);
  });

  test('equals any other empty progression', () {
    final progression = IntProgression(5, 1);

    final equal = progression == IntProgression(1, 9, step: -2);

    expect(equal, isTrue);
  });

  test('shares the hash code of an equal progression', () {
    final progression = IntProgression(1, 9, step: 3);

    final hash = progression.hashCode;

    expect(hash, IntProgression(1, 7, step: 3).hashCode);
  });

  test('shares the hash code of every empty progression', () {
    final progression = IntProgression(5, 1);

    final hash = progression.hashCode;

    expect(hash, IntProgression(1, 9, step: -2).hashCode);
  });

  test('describes an ascending progression', () {
    final progression = IntProgression(1, 7, step: 3);

    final description = progression.toString();

    expect(description, '1..7 step 3');
  });

  test('describes a descending progression', () {
    final progression = IntProgression(7, 1, step: -3);

    final description = progression.toString();

    expect(description, '7 downTo 1 step 3');
  });
}
