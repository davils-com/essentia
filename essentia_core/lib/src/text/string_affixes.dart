/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

import 'package:meta/meta.dart';

/// The first code unit of a UTF-16 high surrogate.
const _highSurrogateStart = 0xD800;

/// The last code unit of a UTF-16 high surrogate.
const _highSurrogateEnd = 0xDBFF;

/// The first code unit of a UTF-16 low surrogate.
const _lowSurrogateStart = 0xDC00;

/// The last code unit of a UTF-16 low surrogate.
const _lowSurrogateEnd = 0xDFFF;

/// Kotlin's prefix and suffix operations: `removePrefix`, `removeSuffix`,
/// `removeSurrounding`, `commonPrefixWith` and `commonSuffixWith`.
extension StringAffixes on String {
  /// Removes [prefix] from the start of the text.
  ///
  /// Kotlin's `String.removePrefix`.
  ///
  /// Returns the text without [prefix], or the text itself when it does not
  /// start with [prefix].
  @useResult
  String removePrefix(String prefix) =>
      startsWith(prefix) ? substring(prefix.length) : this;

  /// Removes [suffix] from the end of the text.
  ///
  /// Kotlin's `String.removeSuffix`.
  ///
  /// Returns the text without [suffix], or the text itself when it does not
  /// end with [suffix].
  @useResult
  String removeSuffix(String suffix) =>
      endsWith(suffix) ? substring(0, length - suffix.length) : this;

  /// Removes [prefix] from the start and [suffix] from the end of the text,
  /// but only when both are there and do not overlap.
  ///
  /// Without [suffix], [prefix] is removed from both ends. Kotlin's
  /// `String.removeSurrounding`.
  ///
  /// Returns the text between both delimiters, or the text itself when
  /// either is missing.
  @useResult
  String removeSurrounding(String prefix, [String? suffix]) {
    final String end = suffix ?? prefix;
    final bool surrounded =
        length >= prefix.length + end.length &&
        startsWith(prefix) &&
        endsWith(end);
    return surrounded ? substring(prefix.length, length - end.length) : this;
  }

  /// The longest text both this text and [other] start with.
  ///
  /// Never ends inside a surrogate pair of either text. Kotlin's
  /// `CharSequence.commonPrefixWith`.
  ///
  /// Returns the common prefix, empty when there is none.
  @useResult
  String commonPrefixWith(String other) {
    final int shortest = min(length, other.length);
    var count = 0;
    while (count < shortest && codeUnitAt(count) == other.codeUnitAt(count)) {
      count++;
    }
    if (_hasSurrogatePairAt(count - 1) ||
        other._hasSurrogatePairAt(count - 1)) {
      count--;
    }
    return substring(0, count);
  }

  /// The longest text both this text and [other] end with.
  ///
  /// Never starts inside a surrogate pair of either text. Kotlin's
  /// `CharSequence.commonSuffixWith`.
  ///
  /// Returns the common suffix, empty when there is none.
  @useResult
  String commonSuffixWith(String other) {
    final int shortest = min(length, other.length);
    var count = 0;
    while (count < shortest &&
        codeUnitAt(length - count - 1) ==
            other.codeUnitAt(other.length - count - 1)) {
      count++;
    }
    if (_hasSurrogatePairAt(length - count - 1) ||
        other._hasSurrogatePairAt(other.length - count - 1)) {
      count--;
    }
    return substring(length - count);
  }

  /// Whether a whole surrogate pair starts at code unit [index].
  bool _hasSurrogatePairAt(int index) =>
      index >= 0 &&
      index < length - 1 &&
      _within(codeUnitAt(index), _highSurrogateStart, _highSurrogateEnd) &&
      _within(codeUnitAt(index + 1), _lowSurrogateStart, _lowSurrogateEnd);
}

/// Whether [codeUnit] lies between [start] and [end], both included.
bool _within(int codeUnit, int start, int end) =>
    start <= codeUnit && codeUnit <= end;
