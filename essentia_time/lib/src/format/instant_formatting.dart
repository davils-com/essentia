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

import 'package:essentia_time/src/date/local_date_time.dart';
import 'package:essentia_time/src/format/date_time_format.dart';
import 'package:essentia_time/src/instant.dart';
import 'package:essentia_time/src/zone/time_zone.dart';

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
