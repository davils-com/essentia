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
import 'package:essentia_time/src/date/local_date_time.dart';
import 'package:essentia_time/src/date/local_time.dart';
import 'package:essentia_time/src/format/date_format_builder.dart';
import 'package:essentia_time/src/format/date_time_format.dart';
import 'package:essentia_time/src/format/date_time_format_builder.dart';
import 'package:essentia_time/src/format/time_format_builder.dart';

/// Builds a format of a [LocalDateTime] from a configuration block,
/// Kotlin's `LocalDateTime.Format { }`.
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

/// Builds a format of a [LocalDate] from a configuration block, Kotlin's
/// `LocalDate.Format { }`.
///
/// Returns the format.
DateTimeFormat<LocalDate> localDateFormat(
  void Function(DateFormatBuilder it) block,
) => DateFormatBuilder().apply(block).build();

/// Builds a format of a [LocalTime] from a configuration block, Kotlin's
/// `LocalTime.Format { }`.
///
/// Returns the format.
DateTimeFormat<LocalTime> localTimeFormat(
  void Function(TimeFormatBuilder it) block,
) => TimeFormatBuilder().apply(block).build();
