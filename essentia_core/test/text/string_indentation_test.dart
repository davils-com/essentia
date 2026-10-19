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

import 'package:essentia_core/src/text/string_indentation.dart';
import 'package:test/test.dart';

/// Covers `lines`, `trimIndent`, `replaceIndent`, `trimMargin` and
/// `prependIndent`.
void main() {
  test('splits its lines at every kind of line break', () {
    const text = 'a\r\nb\nc\rd';

    final List<String> lines = text.lines();

    expect(lines, <String>['a', 'b', 'c', 'd']);
  });

  test('keeps an empty last line', () {
    const text = 'a\n';

    final List<String> lines = text.lines();

    expect(lines, <String>['a', '']);
  });

  test('trims the common indent of every line', () {
    const text = '''
    ABC
      123
    456
''';

    final String trimmed = text.trimIndent();

    expect(trimmed, 'ABC\n  123\n456');
  });

  test('keeps blank lines inside the text while trimming the indent', () {
    const text = '\n  a\n\n  b\n';

    final String trimmed = text.trimIndent();

    expect(trimmed, 'a\n\nb');
  });

  test('replaces the common indent with a new one', () {
    const text = '  a\n    b';

    final String indented = text.replaceIndent('> ');

    expect(indented, '> a\n>   b');
  });

  test('trims every line up to its margin', () {
    const text = 'ABC\n                |123\n                |456';

    final String trimmed = text.trimMargin();

    expect(trimmed, 'ABC\n123\n456');
  });

  test('trims every line up to a custom margin', () {
    const text = '\n  #a\n  #b\n';

    final String trimmed = text.trimMargin('#');

    expect(trimmed, 'a\nb');
  });

  test(
    'keeps a line whose content is only whitespace while trimming margins',
    () {
      const text = 'a\n   \n|b';

      final String trimmed = text.trimMargin();

      expect(trimmed, 'a\n   \nb');
    },
  );

  test('refuses a blank margin prefix', () {
    const text = 'a';

    String trim() => text.trimMargin(' ');

    expect(trim, throwsArgumentError);
  });

  test('prepends an indent to every line', () {
    const text = 'a\nb';

    final String indented = text.prependIndent();

    expect(indented, '    a\n    b');
  });

  test('pads short blank lines to the indent', () {
    const text = 'a\n\nb';

    final String indented = text.prependIndent('> ');

    expect(indented, '> a\n> \n> b');
  });

  test('keeps long blank lines as they are', () {
    const text = 'a\n     ';

    final String indented = text.prependIndent('> ');

    expect(indented, '> a\n     ');
  });
}
