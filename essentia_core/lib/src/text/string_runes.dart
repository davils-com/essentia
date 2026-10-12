/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Kotlin's character predicates on text: `count`, `filter`, `filterNot`,
/// `all`, `any`, `none` and `reversed`.
///
/// They work on whole characters, so a surrogate pair is handed to a
/// predicate as one character, never as two halves.
extension StringRunes on String {
  /// Every character of the text, each as its own string.
  Iterable<String> get _characters => runes.map(String.fromCharCode);

  /// Counts the characters that satisfy [predicate].
  ///
  /// Kotlin's `CharSequence.count(predicate)`.
  ///
  /// Returns the number of matching characters.
  @useResult
  int countWhere(bool Function(String character) predicate) =>
      _characters.where(predicate).length;

  /// Keeps the characters that satisfy [predicate].
  ///
  /// Kotlin's `String.filter`.
  ///
  /// Returns the matching characters in their order.
  @useResult
  String where(bool Function(String character) predicate) =>
      _characters.where(predicate).join();

  /// Keeps the characters that do not satisfy [predicate].
  ///
  /// Kotlin's `String.filterNot`.
  ///
  /// Returns the other characters in their order.
  @useResult
  String whereNot(bool Function(String character) predicate) =>
      where((character) => !predicate(character));

  /// Whether every character satisfies [predicate].
  ///
  /// Kotlin's `CharSequence.all`.
  ///
  /// Returns `true` when all do, and for empty text.
  @useResult
  bool every(bool Function(String character) predicate) =>
      _characters.every(predicate);

  /// Whether any character satisfies [predicate].
  ///
  /// Kotlin's `CharSequence.any(predicate)`.
  ///
  /// Returns `true` when at least one does.
  @useResult
  bool any(bool Function(String character) predicate) =>
      _characters.any(predicate);

  /// Whether no character satisfies [predicate].
  ///
  /// Kotlin's `CharSequence.none(predicate)`.
  ///
  /// Returns `true` when none does, and for empty text.
  @useResult
  bool none(bool Function(String character) predicate) => !any(predicate);

  /// The characters of the text in reverse order.
  ///
  /// Unlike Kotlin's `String.reversed`, a surrogate pair stays whole.
  ///
  /// Returns the reversed text.
  @useResult
  String reversed() => String.fromCharCodes(runes.toList().reversed);
}
