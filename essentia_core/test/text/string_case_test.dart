/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
    const text = 'Kotlin';

    final String decapitalized = text.decapitalize();

    expect(decapitalized, 'kotlin');
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
