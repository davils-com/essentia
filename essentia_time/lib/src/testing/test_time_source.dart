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
