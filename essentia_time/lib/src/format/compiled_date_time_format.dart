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
import 'package:essentia_time/src/date/local_date_time.dart';
import 'package:essentia_time/src/date/local_time.dart';
import 'package:essentia_time/src/format/date_time_format.dart';
import 'package:essentia_time/src/format/format_directive.dart';
import 'package:meta/meta.dart';

/// A [DateTimeFormat] compiled into the list of directives it runs in
/// order, one subtype for each kind of value it writes.
@internal
@immutable
sealed class CompiledDateTimeFormat<T> implements DateTimeFormat<T> {
  /// Creates the format that writes with [directives], which nobody
  /// changes afterwards.
  const CompiledDateTimeFormat(this.directives);

  /// The directives, in the order they write.
  final List<FormatDirective> directives;

  /// Takes [value] apart into the date and the time of day the directives
  /// read.
  ///
  /// Returns both.
  (LocalDate, LocalTime) fieldsOf(T value);

  /// Writes [value] in this format.
  ///
  /// Returns the text.
  @override
  String format(T value) {
    final buffer = StringBuffer();
    formatTo(buffer, value);
    return buffer.toString();
  }

  /// Writes [value] in this format to [out].
  @override
  void formatTo(StringSink out, T value) {
    final (LocalDate date, LocalTime time) = fieldsOf(value);
    for (final FormatDirective directive in directives) {
      directive.appendTo(out, date, time);
    }
  }
}

/// A compiled format of a [LocalDateTime].
@internal
final class CompiledLocalDateTimeFormat
    extends CompiledDateTimeFormat<LocalDateTime> {
  /// Creates the format that writes with [directives].
  const CompiledLocalDateTimeFormat(super.directives);

  /// The date and the time of day of [value].
  ///
  /// Returns both.
  @override
  (LocalDate, LocalTime) fieldsOf(LocalDateTime value) =>
      (value.date, value.time);
}

/// A compiled format of a [LocalDate].
@internal
final class CompiledLocalDateFormat extends CompiledDateTimeFormat<LocalDate> {
  /// Creates the format that writes with [directives].
  const CompiledLocalDateFormat(super.directives);

  /// [value] and a time of day no directive of a date reads.
  ///
  /// Returns both.
  @override
  (LocalDate, LocalTime) fieldsOf(LocalDate value) =>
      (value, LocalTime.midnight);
}

/// A compiled format of a [LocalTime].
@internal
final class CompiledLocalTimeFormat extends CompiledDateTimeFormat<LocalTime> {
  /// Creates the format that writes with [directives].
  const CompiledLocalTimeFormat(super.directives);

  /// A date no directive of a time of day reads.
  static final _anyDate = LocalDate(1970, 1, 1);

  /// A date no directive of a time of day reads, and [value].
  ///
  /// Returns both.
  @override
  (LocalDate, LocalTime) fieldsOf(LocalTime value) => (_anyDate, value);
}
