/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
