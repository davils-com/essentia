/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_time/src/date/local_time.dart';
import 'package:essentia_time/src/format/compiled_date_time_format.dart';
import 'package:essentia_time/src/format/date_time_format.dart';
import 'package:essentia_time/src/format/format_directive.dart';

/// The builder behind `localTimeFormat`: every call appends one field or
/// literal, written in the order of the calls.
final class TimeFormatBuilder implements Builder<DateTimeFormat<LocalTime>> {
  /// Creates the builder of a format that writes nothing yet.
  TimeFormatBuilder();

  /// The directives appended so far.
  final _directives = <FormatDirective>[];

  /// Writes the hour of the day with two digits, `00` to `23`.
  void hour() => _directives.add(const HourDirective());

  /// Writes the minute of the hour with two digits, `00` to `59`.
  void minute() => _directives.add(const MinuteDirective());

  /// Writes the second of the minute with two digits, `00` to `59`.
  void second() => _directives.add(const SecondDirective());

  /// Writes the fraction of the second with exactly [fixedLength] digits,
  /// 1 to 9; the digits beyond them are cut off, not rounded, so `.999`
  /// of a second never becomes the next second.
  ///
  /// Throws a [RangeError] if [fixedLength] is not between 1 and 9.
  void secondFraction(int fixedLength) {
    RangeError.checkValueInInterval(fixedLength, 1, 9, 'fixedLength');
    _directives.add(SecondFractionDirective(fixedLength));
  }

  /// Writes the time of day in [format], a format of a time of its own.
  void time(DateTimeFormat<LocalTime> format) =>
      _directives.add(TimeDirective(format));

  /// Writes the single [character] as it is.
  ///
  /// Throws an [ArgumentError] if [character] is not exactly one
  /// character.
  void char(String character) {
    if (character.runes.length != 1) {
      throw ArgumentError.value(
        character,
        'character',
        'is not exactly one character',
      );
    }
    _directives.add(LiteralDirective(character));
  }

  /// Writes [text] as it is.
  void chars(String text) {
    if (text.isEmpty) {
      return;
    }
    _directives.add(LiteralDirective(text));
  }

  /// Produces the format.
  ///
  /// Returns the format, which later calls on this builder do not change.
  @override
  DateTimeFormat<LocalTime> build() =>
      CompiledLocalTimeFormat(List<FormatDirective>.unmodifiable(_directives));
}
