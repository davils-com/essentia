/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
