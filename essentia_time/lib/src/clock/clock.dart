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

import 'package:essentia_time/src/clock/system_clock.dart';
import 'package:essentia_time/src/instant.dart';
import 'package:essentia_time/src/source/time_source.dart';

/// A source of the current calendar time.
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
  /// The clock of the system the program runs on.
  static const Clock system = SystemClock();

  /// Reads the current calendar time.
  ///
  /// Returns the moment it is now.
  Instant now();
}
