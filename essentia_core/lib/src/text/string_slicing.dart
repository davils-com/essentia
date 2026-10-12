/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

import 'package:essentia_core/src/collection/window_remainder.dart';
import 'package:essentia_core/src/collection/windows.dart';
import 'package:essentia_core/src/text/runes.dart';
import 'package:meta/meta.dart';

/// Kotlin's slicing operations on text: the `substringBefore` and
/// `substringAfter` family, `take`, `drop` and their variants, `chunked`,
/// `windowed` and `removeRange`.
///
/// Counts and indices are code units; the predicate variants work on whole
/// characters and never split a surrogate pair.
extension StringSlicing on String {
  /// The text before the first occurrence of [delimiter].
  ///
  /// Kotlin's `String.substringBefore(delimiter, missingDelimiterValue)`.
  ///
  /// Returns the text before [delimiter], or [whenMissing], by default the
  /// whole text, when [delimiter] does not occur.
  @useResult
  String substringBefore(String delimiter, {String? whenMissing}) =>
      _before(indexOf(delimiter), whenMissing);

  /// The text after the first occurrence of [delimiter].
  ///
  /// Kotlin's `String.substringAfter(delimiter, missingDelimiterValue)`.
  ///
  /// Returns the text after [delimiter], or [whenMissing], by default the
  /// whole text, when [delimiter] does not occur.
  @useResult
  String substringAfter(String delimiter, {String? whenMissing}) =>
      _after(indexOf(delimiter), delimiter, whenMissing);

  /// The text before the last occurrence of [delimiter].
  ///
  /// Kotlin's `String.substringBeforeLast(delimiter, missingDelimiterValue)`.
  ///
  /// Returns the text before [delimiter], or [whenMissing], by default the
  /// whole text, when [delimiter] does not occur.
  @useResult
  String substringBeforeLast(String delimiter, {String? whenMissing}) =>
      _before(lastIndexOf(delimiter), whenMissing);

  /// The text after the last occurrence of [delimiter].
  ///
  /// Kotlin's `String.substringAfterLast(delimiter, missingDelimiterValue)`.
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
  /// Kotlin's `String.take`.
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
  /// Kotlin's `String.drop`.
  ///
  /// Returns the rest, or empty text when the text is shorter.
  ///
  /// Throws a [RangeError] if [count] is negative.
  @useResult
  String drop(int count) =>
      substring(min(RangeError.checkNotNegative(count, 'count'), length));

  /// The last [count] code units.
  ///
  /// Kotlin's `String.takeLast`.
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
  /// Kotlin's `String.dropLast`.
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
  /// Kotlin's `String.takeWhile`.
  ///
  /// Returns the text up to the first character that does not match.
  @useResult
  String takeWhile(bool Function(String character) predicate) =>
      substring(0, _firstMismatch(predicate));

  /// The text without the leading characters that satisfy [predicate].
  ///
  /// Kotlin's `String.dropWhile`.
  ///
  /// Returns the text from the first character that does not match.
  @useResult
  String dropWhile(bool Function(String character) predicate) =>
      substring(_firstMismatch(predicate));

  /// The trailing characters that satisfy [predicate].
  ///
  /// Kotlin's `String.takeLastWhile`.
  ///
  /// Returns the text after the last character that does not match.
  @useResult
  String takeLastWhile(bool Function(String character) predicate) =>
      substring(_endOfLastMismatch(predicate));

  /// The text without the trailing characters that satisfy [predicate].
  ///
  /// Kotlin's `String.dropLastWhile`.
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
  /// Kotlin's `CharSequence.chunked(size)`.
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
  /// Kotlin's `CharSequence.windowed(size, step, partialWindows)`.
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
  /// Kotlin's `String.removeRange(startIndex, endIndex)`.
  ///
  /// Returns the text without that range.
  ///
  /// Throws a [RangeError] if the range is not within the text.
  @useResult
  String removeRange(int start, int end) => replaceRange(start, end, '');
}
