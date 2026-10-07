/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/time/monotonic_time_source.dart';
import 'package:essentia/src/time/time_mark.dart';

/// A source of time readings that measures how much time has passed,
/// Kotlin's `TimeSource.WithComparableMarks`.
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

  /// The time source of the running program, which never goes backwards,
  /// Kotlin's `TimeSource.Monotonic`.
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
