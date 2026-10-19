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

import 'package:essentia_core/src/collection/window_remainder.dart';
import 'package:essentia_core/src/collection/windows.dart';
import 'package:essentia_core/src/text/runes.dart';
import 'package:meta/meta.dart';

/// Slicing operations on text: the `substringBefore` and
/// `substringAfter` family, `take`, `drop` and their variants, `chunked`,
/// `windowed` and `removeRange`.
///
/// Counts and indices are code units; the predicate variants work on whole
/// characters and never split a surrogate pair.
extension StringSlicing on String {
  /// The text before the first occurrence of [delimiter].
  ///
  /// Returns the text before [delimiter], or [whenMissing], by default the
  /// whole text, when [delimiter] does not occur.
  @useResult
  String substringBefore(String delimiter, {String? whenMissing}) =>
      _before(indexOf(delimiter), whenMissing);

  /// The text after the first occurrence of [delimiter].
  ///
  /// Returns the text after [delimiter], or [whenMissing], by default the
  /// whole text, when [delimiter] does not occur.
  @useResult
  String substringAfter(String delimiter, {String? whenMissing}) =>
      _after(indexOf(delimiter), delimiter, whenMissing);

  /// The text before the last occurrence of [delimiter].
  ///
  /// Returns the text before [delimiter], or [whenMissing], by default the
  /// whole text, when [delimiter] does not occur.
  @useResult
  String substringBeforeLast(String delimiter, {String? whenMissing}) =>
      _before(lastIndexOf(delimiter), whenMissing);

  /// The text after the last occurrence of [delimiter].
  ///
  /// Returns the text after [delimiter], or [whenMissing], by default the
  /// whole text, when [delimiter] does not occur.
  @useResult
  String substringAfterLast(String delimiter, {String? whenMissing}) =>
      _after(lastIndexOf(delimiter), delimiter, whenMissing);

  /// The text before code unit [index].
  ///
  /// Returns the text up to [index], or [whenMissing], by default the whole
  /// text, when [index] is negative.
  String _before(int index, String? whenMissing) =>
      index < 0 ? whenMissing ?? this : substring(0, index);

  /// The text after [delimiter] found at code unit [index].
  ///
  /// Returns the text after [delimiter], or [whenMissing], by default the
  /// whole text, when [index] is negative.
  String _after(int index, String delimiter, String? whenMissing) =>
      index < 0 ? whenMissing ?? this : substring(index + delimiter.length);

  /// The first [count] code units.
  ///
  /// Returns the first [count] code units, or the whole text when it is
  /// shorter.
  ///
  /// Throws a [RangeError] if [count] is negative.
  @useResult
  String take(int count) =>
      substring(0, min(RangeError.checkNotNegative(count, 'count'), length));

  /// The text without its first [count] code units.
  ///
  /// Returns the rest, or empty text when the text is shorter.
  ///
  /// Throws a [RangeError] if [count] is negative.
  @useResult
  String drop(int count) =>
      substring(min(RangeError.checkNotNegative(count, 'count'), length));

  /// The last [count] code units.
  ///
  /// Returns the last [count] code units, or the whole text when it is
  /// shorter.
  ///
  /// Throws a [RangeError] if [count] is negative.
  @useResult
  String takeLast(int count) => substring(
    length - min(RangeError.checkNotNegative(count, 'count'), length),
  );

  /// The text without its last [count] code units.
  ///
  /// Returns the rest, or empty text when the text is shorter.
  ///
  /// Throws a [RangeError] if [count] is negative.
  @useResult
  String dropLast(int count) => substring(
    0,
    length - min(RangeError.checkNotNegative(count, 'count'), length),
  );

  /// The leading characters that satisfy [predicate].
  ///
  /// Returns the text up to the first character that does not match.
  @useResult
  String takeWhile(bool Function(String character) predicate) =>
      substring(0, _firstMismatch(predicate));

  /// The text without the leading characters that satisfy [predicate].
  ///
  /// Returns the text from the first character that does not match.
  @useResult
  String dropWhile(bool Function(String character) predicate) =>
      substring(_firstMismatch(predicate));

  /// The trailing characters that satisfy [predicate].
  ///
  /// Returns the text after the last character that does not match.
  @useResult
  String takeLastWhile(bool Function(String character) predicate) =>
      substring(_endOfLastMismatch(predicate));

  /// The text without the trailing characters that satisfy [predicate].
  ///
  /// Returns the text up to and including the last character that does not
  /// match.
  @useResult
  String dropLastWhile(bool Function(String character) predicate) =>
      substring(0, _endOfLastMismatch(predicate));

  /// Where the first character that does not satisfy [predicate] starts.
  ///
  /// Returns its code unit index, or the length when every character
  /// matches.
  int _firstMismatch(bool Function(String character) predicate) {
    final RuneIterator runes = runesAtStart(this);
    while (runes.moveNext()) {
      if (!predicate(runes.currentAsString)) {
        return runes.rawIndex;
      }
    }
    return length;
  }

  /// Where the last character that does not satisfy [predicate] ends.
  ///
  /// Returns the code unit index right after it, or `0` when every
  /// character matches.
  int _endOfLastMismatch(bool Function(String character) predicate) {
    final RuneIterator runes = runesAtEnd(this);
    while (runes.movePrevious()) {
      if (!predicate(runes.currentAsString)) {
        return endOfCurrentRune(runes);
      }
    }
    return 0;
  }

  /// Cuts the text into pieces of [size] code units, the last one possibly
  /// shorter.
  ///
  /// Returns the pieces as an unmodifiable list.
  ///
  /// Throws a [RangeError] if [size] is smaller than one.
  @useResult
  List<String> chunked(int size) =>
      windowed(size, step: size, remainder: WindowRemainder.keep);

  /// Slides a window of [size] code units over the text, moving it [step]
  /// code units at a time.
  ///
  /// [remainder] decides whether the shorter windows at the end are kept.
  ///
  /// Returns the windows as an unmodifiable list.
  ///
  /// Throws a [RangeError] if [size] or [step] is smaller than one.
  @useResult
  List<String> windowed(
    int size, {
    int step = 1,
    WindowRemainder remainder = WindowRemainder.drop,
  }) {
    checkPositive(size, 'size');
    checkPositive(step, 'step');
    final windows = <String>[];
    for (var start = 0; start < length; start += step) {
      final int end = start + size;
      if (end > length && !remainder.keepsPartialWindows) {
        break;
      }
      windows.add(substring(start, min(end, length)));
    }
    return List<String>.unmodifiable(windows);
  }

  /// Removes the code units from [start] up to, not including, [end].
  ///
  /// Returns the text without that range.
  ///
  /// Throws a [RangeError] if the range is not within the text.
  @useResult
  String removeRange(int start, int end) => replaceRange(start, end, '');
}
