/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/time/clock.dart';
import 'package:essentia/src/time/local_date.dart';
import 'package:essentia/src/time/local_date_time.dart';
import 'package:essentia/src/time/time_zone.dart';

/// Reads the date and the time a clock shows in a time zone, Kotlin's
/// `todayIn` and `now().toLocalDateTime(zone)`.
extension ClockDateTime on Clock {
  /// The date it is now in [timeZone], Kotlin's `todayIn`.
  LocalDate todayIn(TimeZone timeZone) => timeZone.toLocalDateTime(now()).date;

  /// The date and time it is now in [timeZone].
  LocalDateTime nowIn(TimeZone timeZone) => timeZone.toLocalDateTime(now());
}
