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
import 'package:essentia_time/src/format/compiled_date_time_format.dart';
import 'package:essentia_time/src/format/date_time_format.dart';
import 'package:essentia_time/src/format/format_directive.dart';

/// The formats most programs need, every field at its full width.
///
/// Unlike the ISO 8601 `toString` of the values, which leaves out a zero
/// second and fraction, these always write the seconds and three digits
/// of their fraction, so every text they write has the same length and
/// sorts like the moment it stands for.
abstract final class DateTimeFormats {
  /// The date as ISO 8601 writes it: `2026-10-10`, `yyyy-MM-dd`.
  static const DateTimeFormat<LocalDate> isoDate = CompiledLocalDateFormat(
    <FormatDirective>[
      YearDirective(),
      LiteralDirective('-'),
      MonthNumberDirective(),
      LiteralDirective('-'),
      DayDirective(),
    ],
  );

  /// The time of day to the millisecond: `09:05:00.000`, `HH:mm:ss.SSS`.
  static const DateTimeFormat<LocalTime> time = CompiledLocalTimeFormat(
    <FormatDirective>[
      HourDirective(),
      LiteralDirective(':'),
      MinuteDirective(),
      LiteralDirective(':'),
      SecondDirective(),
      LiteralDirective('.'),
      SecondFractionDirective(3),
    ],
  );

  /// The date and the time of day, separated by a space:
  /// `2026-10-10 09:05:00.000`, `yyyy-MM-dd HH:mm:ss.SSS`.
  static const DateTimeFormat<LocalDateTime> dateTime =
      CompiledLocalDateTimeFormat(<FormatDirective>[
        DateDirective(isoDate),
        LiteralDirective(' '),
        TimeDirective(time),
      ]);

  /// The date and the time of day as ISO 8601 writes them, at a fixed
  /// width: `2026-10-10T09:05:00.000`, `yyyy-MM-dd'T'HH:mm:ss.SSS`.
  static const DateTimeFormat<LocalDateTime> isoLocal =
      CompiledLocalDateTimeFormat(<FormatDirective>[
        DateDirective(isoDate),
        LiteralDirective('T'),
        TimeDirective(time),
      ]);

  /// A moment in UTC as ISO 8601 writes it, at a fixed width:
  /// `2026-10-10T09:05:00.000Z`, `yyyy-MM-dd'T'HH:mm:ss.SSS'Z'`.
  ///
  /// It writes the date and time it is given followed by `Z`, so it is
  /// meant for the date and time of an instant in UTC, which
  /// `instant.format(DateTimeFormats.isoInstantUtc)` hands it.
  static const DateTimeFormat<LocalDateTime> isoInstantUtc =
      CompiledLocalDateTimeFormat(<FormatDirective>[
        DateDirective(isoDate),
        LiteralDirective('T'),
        TimeDirective(time),
        LiteralDirective('Z'),
      ]);
}
