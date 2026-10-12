/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_time/src/clock/system_clock.dart';
import 'package:essentia_time/src/instant.dart';
import 'package:essentia_time/src/source/time_source.dart';

/// A source of the current calendar time, Kotlin's `kotlin.time.Clock`.
///
/// A clock tells what time it is, which a [TimeSource] cannot; it can also
/// jump, which a time source never does. Use a clock to stamp what happened
/// and to meet a calendar deadline, and a time source to measure how long
/// something took.
///
/// Code that reads the time takes a clock instead of calling
/// `DateTime.now()`, so a test can hand it a fixed one. `todayIn` and
/// `nowIn` read the date and time a clock in a time zone shows.
abstract interface class Clock {
  /// The clock of the system the program runs on, Kotlin's `Clock.System`.
  static const Clock system = SystemClock();

  /// Reads the current calendar time.
  ///
  /// Returns the moment it is now.
  Instant now();
}
