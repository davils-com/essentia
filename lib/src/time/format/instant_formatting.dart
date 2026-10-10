/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/time/format/date_time_format.dart';
import 'package:essentia/src/time/instant.dart';
import 'package:essentia/src/time/local_date_time.dart';
import 'package:essentia/src/time/time_zone.dart';

/// Writes an [Instant] in a format of a date and time.
extension InstantFormatting on Instant {
  /// Writes the date and time this instant shows in [zone], UTC unless
  /// said otherwise, in [format].
  ///
  /// ```dart
  /// clock.now().format(DateTimeFormats.isoInstantUtc);
  /// clock.now().format(DateTimeFormats.dateTime, TimeZone.of('Europe/Berlin'));
  /// ```
  ///
  /// Returns the text.
  String format(
    DateTimeFormat<LocalDateTime> format, [
    TimeZone zone = TimeZone.utc,
  ]) => format.format(toLocalDateTime(zone));
}
