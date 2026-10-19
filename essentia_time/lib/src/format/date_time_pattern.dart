/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_time/src/date/local_date_time.dart';
import 'package:essentia_time/src/format/date_time_format.dart';
import 'package:essentia_time/src/format/date_time_format_builder.dart';

/// The quote that encloses literal text in a pattern.
const _quote = "'";

/// Compiles [pattern], written in the pattern letters below, into a
/// format of a [LocalDateTime].
///
/// | Letters | Writes |
/// |---|---|
/// | `yyyy` | the year, with a sign before 0 and after 9999 |
/// | `MM` | the month number, `01` to `12` |
/// | `dd` | the day of the month, `01` to `31` |
/// | `HH` | the hour, `00` to `23` |
/// | `mm` | the minute, `00` to `59` |
/// | `ss` | the second, `00` to `59` |
/// | `S` to `SSSSSSSSS` | the fraction of the second, cut off |
///
/// Text in single quotes is written as it is, and two single quotes write
/// one, inside quotes and outside. Every other character that is not an
/// ASCII letter is written as it is; the ASCII letters are reserved, so a
/// letter meant as text, like the `T` of ISO 8601, is quoted.
///
/// ```dart
/// localDateTimePattern("yyyy-MM-dd'T'HH:mm:ss.SSS");
/// ```
///
/// Returns the format.
///
/// Throws an [ArgumentError] for a letter the pattern does not know, a
/// field of an unsupported width, or a quote that is not closed.
DateTimeFormat<LocalDateTime> localDateTimePattern(String pattern) {
  final builder = DateTimeFormatBuilder();
  var index = 0;
  while (index < pattern.length) {
    final String character = pattern[index];
    if (character == _quote) {
      index = _quoted(pattern, index, builder);
      continue;
    }
    if (_isLetter(character)) {
      final int end = _runEnd(pattern, index);
      _field(pattern, index, end - index, builder);
      index = end;
      continue;
    }
    final int end = _literalEnd(pattern, index);
    builder.chars(pattern.substring(index, end));
    index = end;
  }
  return builder.build();
}

/// Appends the text quoted at [start] of [pattern] to [builder].
///
/// Returns the index after the closing quote.
///
/// Throws an [ArgumentError] if the quote is not closed.
int _quoted(String pattern, int start, DateTimeFormatBuilder builder) {
  final text = StringBuffer();
  int index = start + 1;
  if (index < pattern.length && pattern[index] == _quote) {
    builder.char(_quote);
    return index + 1;
  }
  while (index < pattern.length) {
    final String character = pattern[index];
    if (character != _quote) {
      text.write(character);
      index++;
      continue;
    }
    if (index + 1 < pattern.length && pattern[index + 1] == _quote) {
      text.write(_quote);
      index += 2;
      continue;
    }
    builder.chars(text.toString());
    return index + 1;
  }
  throw ArgumentError.value(
    pattern,
    'pattern',
    'has a quote at index $start that is not closed',
  );
}

/// Appends the field of the letter at [start] of [pattern], repeated
/// [count] times, to [builder].
///
/// Throws an [ArgumentError] for a letter the pattern does not know or a
/// width it does not support.
void _field(
  String pattern,
  int start,
  int count,
  DateTimeFormatBuilder builder,
) {
  final String letter = pattern[start];
  final String field = letter * count;
  if (letter == 'S' && count <= 9) {
    builder.secondFraction(count);
    return;
  }
  if (field == 'yyyy') {
    builder.year();
    return;
  }
  if (field == 'MM') {
    builder.monthNumber();
    return;
  }
  if (field == 'dd') {
    builder.day();
    return;
  }
  if (field == 'HH') {
    builder.hour();
    return;
  }
  if (field == 'mm') {
    builder.minute();
    return;
  }
  if (field == 'ss') {
    builder.second();
    return;
  }
  throw ArgumentError.value(
    pattern,
    'pattern',
    "has '$field' at index $start, which is not one of yyyy, MM, dd, HH, "
        'mm, ss and S to SSSSSSSSS; quote a letter meant as text',
  );
}

/// Whether [character] is an ASCII letter.
///
/// Returns `true` for `A` to `Z` and `a` to `z`.
bool _isLetter(String character) {
  final int unit = character.codeUnitAt(0);
  return (unit >= 0x41 && unit <= 0x5A) || (unit >= 0x61 && unit <= 0x7A);
}

/// The end of the run of the letter at [start] of [pattern].
///
/// Returns the index of the first other character, or the length.
int _runEnd(String pattern, int start) {
  int end = start + 1;
  while (end < pattern.length && pattern[end] == pattern[start]) {
    end++;
  }
  return end;
}

/// The end of the plain text that starts at [start] of [pattern].
///
/// Returns the index of the next letter or quote, or the length.
int _literalEnd(String pattern, int start) {
  int end = start + 1;
  while (end < pattern.length &&
      pattern[end] != _quote &&
      !_isLetter(pattern[end])) {
    end++;
  }
  return end;
}
