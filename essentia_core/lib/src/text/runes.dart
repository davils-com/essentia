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

import 'package:meta/meta.dart';

/// Walks the characters of [text] from its start.
///
/// Returns an iterator positioned before the first character.
@internal
RuneIterator runesAtStart(String text) => RuneIterator(text);

/// Walks the characters of [text] from its end.
///
/// Returns an iterator positioned after the last character.
@internal
RuneIterator runesAtEnd(String text) => RuneIterator.at(text, text.length);

/// The code unit index right after the character [runes] is at.
///
/// Returns the index.
@internal
int endOfCurrentRune(RuneIterator runes) => runes.rawIndex + runes.currentSize;

/// Whether [character] is white space.
@internal
bool isWhitespace(String character) => character.trim().isEmpty;

/// How many white space characters [line] starts with.
///
/// Returns the width of the indentation, the whole length for a blank line.
@internal
int indentWidth(String line) {
  final int index = line
      .split('')
      .indexWhere((character) => !isWhitespace(character));
  return index < 0 ? line.length : index;
}
