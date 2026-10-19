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

import 'package:essentia_time/src/date/local_date.dart';
import 'package:essentia_time/src/date/local_time.dart';
import 'package:essentia_time/src/format/date_time_format.dart';
import 'package:essentia_time/src/internal/iso_text.dart';
import 'package:meta/meta.dart';

/// One step of a compiled date and time format: a field or a literal it
/// writes.
@internal
@immutable
sealed class FormatDirective {
  /// Creates the directive.
  const FormatDirective();

  /// Writes the part of [date] and [time] this directive stands for to
  /// [out].
  void appendTo(StringSink out, LocalDate date, LocalTime time);
}

/// Writes the year with at least four digits, with a sign before year 0
/// and after year 9999, as ISO 8601 does.
@internal
final class YearDirective extends FormatDirective {
  /// Creates the directive.
  const YearDirective();

  /// Writes the year of [date].
  @override
  void appendTo(StringSink out, LocalDate date, LocalTime time) =>
      out.write(isoYear(date.year));
}

/// Writes the number of the month with two digits.
@internal
final class MonthNumberDirective extends FormatDirective {
  /// Creates the directive.
  const MonthNumberDirective();

  /// Writes the month number of [date].
  @override
  void appendTo(StringSink out, LocalDate date, LocalTime time) =>
      out.write(twoDigits(date.monthNumber));
}

/// Writes the day of the month with two digits.
@internal
final class DayDirective extends FormatDirective {
  /// Creates the directive.
  const DayDirective();

  /// Writes the day of [date].
  @override
  void appendTo(StringSink out, LocalDate date, LocalTime time) =>
      out.write(twoDigits(date.day));
}

/// Writes the hour of the day, 0 to 23, with two digits.
@internal
final class HourDirective extends FormatDirective {
  /// Creates the directive.
  const HourDirective();

  /// Writes the hour of [time].
  @override
  void appendTo(StringSink out, LocalDate date, LocalTime time) =>
      out.write(twoDigits(time.hour));
}

/// Writes the minute of the hour with two digits.
@internal
final class MinuteDirective extends FormatDirective {
  /// Creates the directive.
  const MinuteDirective();

  /// Writes the minute of [time].
  @override
  void appendTo(StringSink out, LocalDate date, LocalTime time) =>
      out.write(twoDigits(time.minute));
}

/// Writes the second of the minute with two digits.
@internal
final class SecondDirective extends FormatDirective {
  /// Creates the directive.
  const SecondDirective();

  /// Writes the second of [time].
  @override
  void appendTo(StringSink out, LocalDate date, LocalTime time) =>
      out.write(twoDigits(time.second));
}

/// Writes the fraction of the second with exactly [length] digits, the
/// digits beyond them cut off rather than rounded.
@internal
final class SecondFractionDirective extends FormatDirective {
  /// Creates the directive writing [length] digits, 1 to 9.
  const SecondFractionDirective(this.length);

  /// How many nanoseconds one unit of the last digit is, by the number of
  /// digits.
  static const _units = <int>[
    1000000000,
    100000000,
    10000000,
    1000000,
    100000,
    10000,
    1000,
    100,
    10,
    1,
  ];

  /// The number of digits written.
  final int length;

  /// Writes the first [length] digits of the fraction of [time].
  @override
  void appendTo(StringSink out, LocalDate date, LocalTime time) =>
      out.write(padDigits(time.nanosecond ~/ _units[length], length));
}

/// Writes fixed [text].
@internal
final class LiteralDirective extends FormatDirective {
  /// Creates the directive writing [text].
  const LiteralDirective(this.text);

  /// The text written.
  final String text;

  /// Writes [text].
  @override
  void appendTo(StringSink out, LocalDate date, LocalTime time) =>
      out.write(text);
}

/// Writes the date in a format of its own.
@internal
final class DateDirective extends FormatDirective {
  /// Creates the directive writing the date in [format].
  const DateDirective(this.format);

  /// The format of the date.
  final DateTimeFormat<LocalDate> format;

  /// Writes [date] in [format].
  @override
  void appendTo(StringSink out, LocalDate date, LocalTime time) =>
      format.formatTo(out, date);
}

/// Writes the time of day in a format of its own.
@internal
final class TimeDirective extends FormatDirective {
  /// Creates the directive writing the time in [format].
  const TimeDirective(this.format);

  /// The format of the time of day.
  final DateTimeFormat<LocalTime> format;

  /// Writes [time] in [format].
  @override
  void appendTo(StringSink out, LocalDate date, LocalTime time) =>
      format.formatTo(out, time);
}
