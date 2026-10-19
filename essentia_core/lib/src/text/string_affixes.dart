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

/// Prefix and suffix operations on text: `removePrefix`, `removeSuffix`,
/// `removeSurrounding`, `commonPrefixWith` and `commonSuffixWith`.
extension StringAffixes on String {
  /// Removes [prefix] from the start of the text.
  ///
  /// Returns the text without [prefix], or the text itself when it does not
  /// start with [prefix].
  @useResult
  String removePrefix(String prefix) =>
      startsWith(prefix) ? substring(prefix.length) : this;

  /// Removes [suffix] from the end of the text.
  ///
  /// Returns the text without [suffix], or the text itself when it does not
  /// end with [suffix].
  @useResult
  String removeSuffix(String suffix) =>
      endsWith(suffix) ? substring(0, length - suffix.length) : this;

  /// Removes [prefix] from the start and [suffix] from the end of the text,
  /// but only when both are there and do not overlap.
  ///
  /// Without [suffix], [prefix] is removed from both ends.
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
  /// Never ends inside a surrogate pair of either text.
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
  /// Never starts inside a surrogate pair of either text.
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
