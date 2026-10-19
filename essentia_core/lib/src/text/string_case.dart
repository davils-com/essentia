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

import 'package:essentia_core/src/text/runes.dart';
import 'package:meta/meta.dart';

/// Case operations on text: `capitalize`, `decapitalize`,
/// `replaceFirstChar` and the comparisons that ignore case.
extension StringCase on String {
  /// Turns the first character into upper case.
  ///
  /// Returns the text with its first character in upper case.
  @useResult
  String capitalize() =>
      replaceFirstChar((character) => character.toUpperCase());

  /// Turns the first character into lower case.
  ///
  /// Returns the text with its first character in lower case.
  @useResult
  String decapitalize() =>
      replaceFirstChar((character) => character.toLowerCase());

  /// Replaces the first character by what [transform] makes of it.
  ///
  /// A surrogate pair is handed to [transform] as a whole.
  ///
  /// Returns the text with its first character replaced, or the text itself
  /// when it is empty.
  @useResult
  String replaceFirstChar(String Function(String character) transform) {
    final RuneIterator runes = runesAtStart(this);
    if (!runes.moveNext()) {
      return this;
    }
    return '${transform(runes.currentAsString)}'
        '${substring(endOfCurrentRune(runes))}';
  }

  /// Whether the text equals [other] when case is ignored.
  ///
  /// Returns `true` when both are the same in lower case.
  @useResult
  bool equalsIgnoreCase(String other) => toLowerCase() == other.toLowerCase();

  /// Whether the text starts with [prefix] when case is ignored.
  ///
  /// Returns `true` when it does.
  @useResult
  bool startsWithIgnoreCase(String prefix) =>
      toLowerCase().startsWith(prefix.toLowerCase());

  /// Whether the text ends with [suffix] when case is ignored.
  ///
  /// Returns `true` when it does.
  @useResult
  bool endsWithIgnoreCase(String suffix) =>
      toLowerCase().endsWith(suffix.toLowerCase());

  /// Whether the text contains [other] when case is ignored.
  ///
  /// Returns `true` when it does.
  @useResult
  bool containsIgnoreCase(String other) =>
      toLowerCase().contains(other.toLowerCase());
}
