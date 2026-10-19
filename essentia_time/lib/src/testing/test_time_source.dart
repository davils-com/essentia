/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_time/src/source/time_source.dart';

/// A time source that only moves when it is told to.
///
/// It starts at zero and moves on by exactly what [advance] is given, so a
/// test decides how much time has passed and never waits for it.
///
/// ```dart
/// final time = TestTimeSource();
/// final TimeMark start = time.markNow();
/// time.advance(3.seconds);
/// expect(start.elapsedNow(), 3.seconds);
/// ```
final class TestTimeSource extends TimeSource {
  /// Creates a time source reading zero.
  TestTimeSource();

  /// The current reading.
  Duration _reading = Duration.zero;

  /// Reads the time this source was advanced by in total.
  ///
  /// Returns the current reading.
  @override
  Duration read() => _reading;

  /// Moves the reading on by [duration].
  ///
  /// A negative duration is refused: a time source never goes
  /// backwards, and a test that needs it to is testing something no real
  /// source does.
  ///
  /// Throws an [ArgumentError] if [duration] is negative.
  void advance(Duration duration) {
    if (duration.isNegative) {
      throw ArgumentError.value(
        duration,
        'duration',
        'A time source never goes backwards',
      );
    }
    _reading += duration;
  }

  /// Renders the current reading.
  @override
  String toString() => 'TestTimeSource($_reading)';
}
