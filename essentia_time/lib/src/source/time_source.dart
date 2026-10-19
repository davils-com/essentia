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

import 'package:essentia_time/src/source/monotonic_time_source.dart';
import 'package:essentia_time/src/source/time_mark.dart';

/// A source of time readings that measures how much time has passed.
///
/// A reading says nothing about the time of day: it is the time passed
/// since an origin of the source's choosing, and only two readings of the
/// same source can be compared. That is what makes a time source the right
/// tool for timeouts, rates and durations, where a wall clock that jumps
/// with the user's settings would be wrong.
///
/// Code that measures time takes a time source instead of reading
/// [monotonic] itself, so a test can hand it a `TestTimeSource` and move
/// time on by hand.
///
/// ```dart
/// final TimeMark start = TimeSource.monotonic.markNow();
/// await work();
/// final Duration took = start.elapsedNow();
/// ```
abstract class TimeSource {
  /// Creates a time source.
  const TimeSource();

  /// The time source of the running program, which never goes backwards.
  static final TimeSource monotonic = MonotonicTimeSource();

  /// Reads the time passed since the origin of this source.
  ///
  /// A later reading is never smaller than an earlier one.
  ///
  /// Returns the current reading.
  Duration read();

  /// Marks the current point in time of this source.
  ///
  /// Returns a mark that tells how much time has passed since it was made.
  TimeMark markNow() => TimeMark(this, read());
}
