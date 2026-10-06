/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/text/nullable_string.dart';
import 'package:test/test.dart';

/// Covers `isNullOrEmpty`, `isNullOrBlank` and `orEmpty` on absent text.
void main() {
  test('treats absent text as empty', () {
    const String? text = null;

    final bool empty = text.isNullOrEmpty;

    expect(empty, isTrue);
  });

  test('treats present text as not empty', () {
    const text = ' ';

    final bool empty = text.isNullOrEmpty;

    expect(empty, isFalse);
  });

  test('treats absent text as blank', () {
    const String? text = null;

    final bool blank = text.isNullOrBlank;

    expect(blank, isTrue);
  });

  test('treats whitespace as blank', () {
    const text = ' ';

    final bool blank = text.isNullOrBlank;

    expect(blank, isTrue);
  });

  test('treats a letter as not blank', () {
    const text = 'a';

    final bool blank = text.isNullOrBlank;

    expect(blank, isFalse);
  });

  test('replaces absent text with empty text', () {
    const String? text = null;

    final String value = text.orEmpty();

    expect(value, '');
  });

  test('keeps present text', () {
    const text = 'a';

    final String value = text.orEmpty();

    expect(value, 'a');
  });
}
