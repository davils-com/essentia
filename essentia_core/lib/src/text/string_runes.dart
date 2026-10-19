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

/// Character predicates on text: `count`, `filter`, `filterNot`,
/// `all`, `any`, `none` and `reversed`.
///
/// They work on whole characters, so a surrogate pair is handed to a
/// predicate as one character, never as two halves.
extension StringRunes on String {
  /// Every character of the text, each as its own string.
  Iterable<String> get _characters => runes.map(String.fromCharCode);

  /// Counts the characters that satisfy [predicate].
  ///
  /// Returns the number of matching characters.
  @useResult
  int countWhere(bool Function(String character) predicate) =>
      _characters.where(predicate).length;

  /// Keeps the characters that satisfy [predicate].
  ///
  /// Returns the matching characters in their order.
  @useResult
  String where(bool Function(String character) predicate) =>
      _characters.where(predicate).join();

  /// Keeps the characters that do not satisfy [predicate].
  ///
  /// Returns the other characters in their order.
  @useResult
  String whereNot(bool Function(String character) predicate) =>
      where((character) => !predicate(character));

  /// Whether every character satisfies [predicate].
  ///
  /// Returns `true` when all do, and for empty text.
  @useResult
  bool every(bool Function(String character) predicate) =>
      _characters.every(predicate);

  /// Whether any character satisfies [predicate].
  ///
  /// Returns `true` when at least one does.
  @useResult
  bool any(bool Function(String character) predicate) =>
      _characters.any(predicate);

  /// Whether no character satisfies [predicate].
  ///
  /// Returns `true` when none does, and for empty text.
  @useResult
  bool none(bool Function(String character) predicate) => !any(predicate);

  /// The characters of the text in reverse order.
  ///
  /// A surrogate pair stays whole.
  ///
  /// Returns the reversed text.
  @useResult
  String reversed() => String.fromCharCodes(runes.toList().reversed);
}
