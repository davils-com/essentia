/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_time/src/clock/clock.dart';
import 'package:essentia_time/src/date/local_date.dart';
import 'package:essentia_time/src/date/local_date_time.dart';
import 'package:essentia_time/src/zone/time_zone.dart';

/// Reads the date and the time a clock shows in a time zone.
extension ClockDateTime on Clock {
  /// The date it is now in [timeZone].
  LocalDate todayIn(TimeZone timeZone) => timeZone.toLocalDateTime(now()).date;

  /// The date and time it is now in [timeZone].
  LocalDateTime nowIn(TimeZone timeZone) => timeZone.toLocalDateTime(now());
}
