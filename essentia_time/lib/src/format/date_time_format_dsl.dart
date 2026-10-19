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

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_time/src/date/local_date.dart';
import 'package:essentia_time/src/date/local_date_time.dart';
import 'package:essentia_time/src/date/local_time.dart';
import 'package:essentia_time/src/format/date_format_builder.dart';
import 'package:essentia_time/src/format/date_time_format.dart';
import 'package:essentia_time/src/format/date_time_format_builder.dart';
import 'package:essentia_time/src/format/time_format_builder.dart';

/// Builds a format of a [LocalDateTime] from a configuration block.
///
/// ```dart
/// final DateTimeFormat<LocalDateTime> stamp = localDateTimeFormat(
///   (it) => it
///     ..date(DateTimeFormats.isoDate)
///     ..char(' ')
///     ..hour()
///     ..char(':')
///     ..minute(),
/// );
/// stamp.format(LocalDateTime.of(2026, 10, 10, 9, 5)); // 2026-10-10 09:05
/// ```
///
/// Returns the format.
DateTimeFormat<LocalDateTime> localDateTimeFormat(
  void Function(DateTimeFormatBuilder it) block,
) => DateTimeFormatBuilder().apply(block).build();

/// Builds a format of a [LocalDate] from a configuration block.
///
/// Returns the format.
DateTimeFormat<LocalDate> localDateFormat(
  void Function(DateFormatBuilder it) block,
) => DateFormatBuilder().apply(block).build();

/// Builds a format of a [LocalTime] from a configuration block.
///
/// Returns the format.
DateTimeFormat<LocalTime> localTimeFormat(
  void Function(TimeFormatBuilder it) block,
) => TimeFormatBuilder().apply(block).build();
