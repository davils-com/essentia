/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/text/runes.dart';
import 'package:meta/meta.dart';

/// Kotlin's case operations on text: `capitalize`, `decapitalize`,
/// `replaceFirstChar` and the comparisons that ignore case.
extension StringCase on String {
  /// Turns the first character into upper case.
  ///
  /// Kotlin's `replaceFirstChar { it.uppercase() }`, the replacement of the
  /// deprecated `capitalize`.
  ///
  /// Returns the text with its first character in upper case.
  @useResult
  String capitalize() =>
      replaceFirstChar((character) => character.toUpperCase());

  /// Turns the first character into lower case.
  ///
  /// Kotlin's `replaceFirstChar { it.lowercase() }`, the replacement of the
  /// deprecated `decapitalize`.
  ///
  /// Returns the text with its first character in lower case.
  @useResult
  String decapitalize() =>
      replaceFirstChar((character) => character.toLowerCase());

  /// Replaces the first character by what [transform] makes of it.
  ///
  /// A surrogate pair is handed to [transform] as a whole. Kotlin's
  /// `String.replaceFirstChar`.
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
  /// Kotlin's `String.equals(other, ignoreCase = true)`.
  ///
  /// Returns `true` when both are the same in lower case.
  @useResult
  bool equalsIgnoreCase(String other) => toLowerCase() == other.toLowerCase();

  /// Whether the text starts with [prefix] when case is ignored.
  ///
  /// Kotlin's `String.startsWith(prefix, ignoreCase = true)`.
  ///
  /// Returns `true` when it does.
  @useResult
  bool startsWithIgnoreCase(String prefix) =>
      toLowerCase().startsWith(prefix.toLowerCase());

  /// Whether the text ends with [suffix] when case is ignored.
  ///
  /// Kotlin's `String.endsWith(suffix, ignoreCase = true)`.
  ///
  /// Returns `true` when it does.
  @useResult
  bool endsWithIgnoreCase(String suffix) =>
      toLowerCase().endsWith(suffix.toLowerCase());

  /// Whether the text contains [other] when case is ignored.
  ///
  /// Kotlin's `CharSequence.contains(other, ignoreCase = true)`.
  ///
  /// Returns `true` when it does.
  @useResult
  bool containsIgnoreCase(String other) =>
      toLowerCase().contains(other.toLowerCase());
}
