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

import 'package:essentia_core/src/collection/list_access.dart';
import 'package:essentia_core/src/range/int_progression.dart';
import 'package:test/test.dart';

/// Three letters to read by index.
const _letters = <String>['a', 'b', 'c'];

/// Covers reading the elements of a list by index.
void main() {
  test('knows the index of its last element', () {
    final int index = _letters.lastIndex;

    expect(index, 2);
  });

  test('reports minus one as the last index of an empty list', () {
    const empty = <String>[];

    final int index = empty.lastIndex;

    expect(index, -1);
  });

  test('spans all of its indices', () {
    final IntRange indices = _letters.indices;

    expect(indices.toList(), <int>[0, 1, 2]);
  });

  test('spans no index when empty', () {
    const empty = <String>[];

    final IntRange indices = empty.indices;

    expect(indices, isEmpty);
  });

  test('reads the element at a valid index', () {
    final String letter = _letters.getOrElse(1, (index) => '?');

    expect(letter, 'b');
  });

  test('falls back beyond the last index', () {
    final String letter = _letters.getOrElse(3, (index) => '#$index');

    expect(letter, '#3');
  });

  test('falls back before the first index', () {
    final String letter = _letters.getOrElse(-1, (index) => '#$index');

    expect(letter, '#-1');
  });

  test('picks the elements at the given indices', () {
    final List<String> picked = _letters.elementsAt(<int>[2, 0, 2]);

    expect(picked, <String>['c', 'a', 'c']);
  });

  test('refuses an index outside the list', () {
    List<String> pick() => _letters.elementsAt(<int>[3]);

    expect(pick, throwsRangeError);
  });

  test('hands out picked elements that cannot be modified', () {
    final List<String> picked = _letters.elementsAt(<int>[0]);

    void modify() => picked.add('z');

    expect(modify, throwsUnsupportedError);
  });
}
