/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_time/src/date/local_date.dart';
import 'package:essentia_time/src/format/compiled_date_time_format.dart';
import 'package:essentia_time/src/format/date_time_format.dart';
import 'package:essentia_time/src/format/format_directive.dart';

/// The builder behind `localDateFormat`, Kotlin's
/// `DateTimeFormatBuilder.WithDate`: every call appends one field or
/// literal, written in the order of the calls.
final class DateFormatBuilder implements Builder<DateTimeFormat<LocalDate>> {
  /// Creates the builder of a format that writes nothing yet.
  DateFormatBuilder();

  /// The directives appended so far.
  final _directives = <FormatDirective>[];

  /// Writes the year with at least four digits, with a sign before year 0
  /// and after year 9999, as ISO 8601 does: `2026`, `0007`, `-0044`,
  /// `+10000`.
  void year() => _directives.add(const YearDirective());

  /// Writes the number of the month with two digits, `01` to `12`.
  void monthNumber() => _directives.add(const MonthNumberDirective());

  /// Writes the day of the month with two digits, `01` to `31`.
  void day() => _directives.add(const DayDirective());

  /// Writes the date in [format], a format of a date of its own.
  void date(DateTimeFormat<LocalDate> format) =>
      _directives.add(DateDirective(format));

  /// Writes the single [character] as it is, Kotlin's `char`.
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

  /// Writes [text] as it is, Kotlin's `chars`.
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
  DateTimeFormat<LocalDate> build() =>
      CompiledLocalDateFormat(List<FormatDirective>.unmodifiable(_directives));
}
