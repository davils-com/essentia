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

import 'package:essentia_core/src/text/string_search.dart';
import 'package:test/test.dart';

/// The text the tests work on.
const _text = 'one two three two';

/// Covers `indexOfAny`, `lastIndexOfAny` and `splitWithLimit`.
void main() {
  test('finds the earliest of several candidates', () {
    final int index = _text.indexOfAny(<String>['three', 'two']);

    expect(index, 4);
  });

  test('finds the earliest candidate after a start', () {
    final int index = _text.indexOfAny(<String>['two'], 5);

    expect(index, 14);
  });

  test('reports minus one when no candidate occurs', () {
    final int index = _text.indexOfAny(<String>['four']);

    expect(index, -1);
  });

  test('finds the latest of several candidates', () {
    final int index = _text.lastIndexOfAny(<String>['one', 'three']);

    expect(index, 8);
  });

  test('finds the latest candidate before a start', () {
    final int index = _text.lastIndexOfAny(<String>['two'], 13);

    expect(index, 4);
  });

  test('splits into at most the given number of parts', () {
    const text = 'a,b,c,d';

    final List<String> parts = text.splitWithLimit(',', 2);

    expect(parts, <String>['a', 'b,c,d']);
  });

  test('splits at every delimiter without a limit', () {
    const text = 'a,b,c';

    final List<String> parts = text.splitWithLimit(',', 0);

    expect(parts, <String>['a', 'b', 'c']);
  });

  test('keeps the whole text as a single part when the limit is one', () {
    const text = 'a,b';

    final List<String> parts = text.splitWithLimit(',', 1);

    expect(parts, <String>['a,b']);
  });

  test('refuses an empty delimiter', () {
    List<String> split() => _text.splitWithLimit('', 2);

    expect(split, throwsArgumentError);
  });

  test('refuses a negative limit', () {
    List<String> split() => _text.splitWithLimit(' ', -1);

    expect(split, throwsRangeError);
  });

  test('hands out parts that cannot be modified', () {
    final List<String> parts = _text.splitWithLimit(' ', 0);

    void modify() => parts.add('x');

    expect(modify, throwsUnsupportedError);
  });
}
