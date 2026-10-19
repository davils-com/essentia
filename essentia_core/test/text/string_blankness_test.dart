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

import 'package:essentia_core/src/text/string_blankness.dart';
import 'package:test/test.dart';

/// Covers `isBlank`, `isNotBlank`, `ifBlank` and `ifEmpty`.
void main() {
  test('considers whitespace only text blank', () {
    const text = ' \t\n';

    final bool blank = text.isBlank;

    expect(blank, isTrue);
  });

  test('considers text with a letter not blank', () {
    const text = ' a ';

    final bool blank = text.isNotBlank;

    expect(blank, isTrue);
  });

  test('falls back when the text is blank', () {
    const text = '  ';

    final String value = text.ifBlank(() => 'none');

    expect(value, 'none');
  });

  test('keeps text that is not blank', () {
    const text = 'a';

    final String value = text.ifBlank(() => 'none');

    expect(value, 'a');
  });

  test('falls back when the text is empty', () {
    const text = '';

    final String value = text.ifEmpty(() => 'none');

    expect(value, 'none');
  });

  test('keeps blank text that is not empty', () {
    const text = ' ';

    final String value = text.ifEmpty(() => 'none');

    expect(value, ' ');
  });
}
