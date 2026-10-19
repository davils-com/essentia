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

import 'package:essentia_core/src/text/string_case.dart';
import 'package:meta/meta.dart';

/// A character in upper case.
final _upperCase = RegExp(r'^\p{Lu}$', unicode: true);

/// A character in lower case.
final _lowerCase = RegExp(r'^\p{Ll}$', unicode: true);

/// A letter of any script.
final _letter = RegExp(r'^\p{L}$', unicode: true);

/// A letter or a digit of any script.
final _letterOrDigit = RegExp(r'^[\p{L}\p{N}]$', unicode: true);

/// Splits names into words and joins them in the spellings programs use for
/// keys: `snake_case`, `kebab-case`, `SCREAMING_SNAKE_CASE`, `camelCase`
/// and `PascalCase`.
///
/// ```dart
/// 'HTTPServer'.toSnakeCase();   // http_server
/// 'retryAfter'.toKebabCase();   // retry-after
/// 'lease_duration'.toCamelCase(); // leaseDuration
/// ```
///
/// [toSnakeCase] and [toKebabCase] treat only capitals as boundaries. A run of
/// capitals keeps its last capital for the word that follows, so `URLs` becomes
/// `ur_ls`.
extension StringWords on String {
  /// Splits the text into its words.
  ///
  /// A word ends at every character that is neither a letter nor a digit,
  /// before a capital that follows a lower case letter or a digit, and
  /// before the last capital of a run that a lower case letter follows:
  /// `HTTPServer` is `HTTP` and `Server`, `lease_duration` is `lease` and
  /// `duration`. The words keep their case.
  ///
  /// Returns the words, none of them empty.
  @useResult
  List<String> words() {
    final List<String> characters = runes.map(String.fromCharCode).toList();
    final words = <String>[];
    final current = StringBuffer();
    for (var index = 0; index < characters.length; index++) {
      final String character = characters[index];
      if (!_letterOrDigit.hasMatch(character)) {
        _flush(current, words);
        continue;
      }
      if (current.isNotEmpty && _upperCase.hasMatch(character)) {
        final bool afterLower = !_upperCase.hasMatch(characters[index - 1]);
        final bool beforeLower =
            index + 1 < characters.length &&
            _lowerCase.hasMatch(characters[index + 1]);
        if (afterLower || beforeLower) {
          _flush(current, words);
        }
      }
      current.write(character);
    }
    _flush(current, words);
    return List<String>.unmodifiable(words);
  }

  /// Spells the text in `snake_case`: `retryAfterSeconds` becomes
  /// `retry_after_seconds`.
  ///
  /// Only capitals are boundaries; every other character, an `_` or a digit
  /// included, is kept where it is.
  ///
  /// Returns the text in snake case.
  @useResult
  String toSnakeCase() => _delimited(this, '_');

  /// Spells the text in `kebab-case`: `retryAfterSeconds` becomes
  /// `retry-after-seconds`.
  ///
  /// The same algorithm as [toSnakeCase] with a `-`.
  ///
  /// Returns the text in kebab case.
  @useResult
  String toKebabCase() => _delimited(this, '-');

  /// Spells the text in `SCREAMING_SNAKE_CASE`: `retryAfter` becomes
  /// `RETRY_AFTER`.
  ///
  /// Returns [toSnakeCase] in upper case.
  @useResult
  String toScreamingSnakeCase() => toSnakeCase().toUpperCase();

  /// Spells the text in `camelCase`: `lease_duration` becomes
  /// `leaseDuration`, `HTTP server` becomes `httpServer`.
  ///
  /// Returns the [words] joined, the first in lower case and every other
  /// one capitalized.
  @useResult
  String toCamelCase() => toPascalCase().decapitalize();

  /// Spells the text in `PascalCase`: `lease_duration` becomes
  /// `LeaseDuration`, `HTTP server` becomes `HttpServer`.
  ///
  /// Returns the [words] joined, each one capitalized.
  @useResult
  String toPascalCase() =>
      words().map((word) => word.toLowerCase().capitalize()).join();
}

/// Moves what [current] holds into [words] as one word, if it holds any.
void _flush(StringBuffer current, List<String> words) {
  if (current.isEmpty) {
    return;
  }
  words.add(current.toString());
  current.clear();
}

/// Lowers every capital of [text] and puts [delimiter] before each run of
/// capitals.
///
/// Returns the delimited text.
String _delimited(String text, String delimiter) {
  final written = <String>[];
  String? buffered;
  var capitalsInRun = 0;
  for (final String character in text.split('')) {
    if (_upperCase.hasMatch(character)) {
      if (capitalsInRun == 0 &&
          written.isNotEmpty &&
          written.last != delimiter) {
        written.add(delimiter);
      }
      written.addAll(<String>[?buffered]);
      capitalsInRun++;
      buffered = character.toLowerCase();
      continue;
    }
    if (buffered != null) {
      if (capitalsInRun > 1 && _letter.hasMatch(character)) {
        written.add(delimiter);
      }
      written.add(buffered);
      capitalsInRun = 0;
      buffered = null;
    }
    written.add(character);
  }
  written.addAll(<String>[?buffered]);
  return written.join();
}
