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

import 'package:essentia_core/src/text/string_case.dart';
import 'package:test/test.dart';

/// Covers capitalization and the comparisons that ignore case.
void main() {
  test('capitalizes the first character', () {
    const text = 'über';

    final String capitalized = text.capitalize();

    expect(capitalized, 'Über');
  });

  test('decapitalizes the first character', () {
    const text = 'Essentia';

    final String decapitalized = text.decapitalize();

    expect(decapitalized, 'essentia');
  });

  test('replaces the first character as a whole surrogate pair', () {
    const text = '😀!';

    final String replaced = text.replaceFirstChar(
      (character) => '[$character]',
    );

    expect(replaced, '[😀]!');
  });

  test('leaves empty text unchanged', () {
    const text = '';

    final String replaced = text.replaceFirstChar((character) => 'x');

    expect(replaced, '');
  });

  test('equals text that differs only in case', () {
    const text = 'Straße';

    final bool equal = text.equalsIgnoreCase('STRAßE');

    expect(equal, isTrue);
  });

  test('keeps ß apart from a double s', () {
    const text = 'straße';

    final bool equal = text.equalsIgnoreCase('STRASSE');

    expect(equal, isFalse);
  });

  test('starts with a prefix in another case', () {
    const text = 'Äpfel';

    final bool starts = text.startsWithIgnoreCase('äp');

    expect(starts, isTrue);
  });

  test('ends with a suffix in another case', () {
    const text = 'README.MD';

    final bool ends = text.endsWithIgnoreCase('.md');

    expect(ends, isTrue);
  });

  test('contains text in another case', () {
    const text = 'Hello World';

    final bool contains = text.containsIgnoreCase('o w');

    expect(contains, isTrue);
  });
}
