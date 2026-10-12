/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/text/string_runes.dart';
import 'package:test/test.dart';

/// The text the tests work on.
const _text = 'a😀b😀';

/// Whether [character] is the grinning face.
bool _isEmoji(String character) => character == '😀';

/// Covers the character predicates and `reversed` on whole characters.
void main() {
  test('counts whole characters that match', () {
    final int count = _text.countWhere(_isEmoji);

    expect(count, 2);
  });

  test('keeps the characters that match', () {
    final String emojis = _text.where(_isEmoji);

    expect(emojis, '😀😀');
  });

  test('keeps the characters that do not match', () {
    final String letters = _text.whereNot(_isEmoji);

    expect(letters, 'ab');
  });

  test('confirms that every character matches', () {
    const text = '😀😀';

    final bool all = text.every(_isEmoji);

    expect(all, isTrue);
  });

  test('finds a character that matches', () {
    final bool found = _text.any((character) => character == 'b');

    expect(found, isTrue);
  });

  test('confirms that no character matches', () {
    final bool nothing = _text.none((character) => character == 'z');

    expect(nothing, isTrue);
  });

  test('reverses whole characters', () {
    const text = 'ab😀';

    final String reversed = text.reversed();

    expect(reversed, '😀ba');
  });
}
