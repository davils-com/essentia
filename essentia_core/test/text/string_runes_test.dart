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
