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
import 'package:meta/meta.dart';

/// The time source behind `TimeSource.monotonic`, a `Stopwatch` started
/// once and never stopped.
///
/// Its origin is the moment it was created, and its resolution is a
/// microsecond, the resolution of a `Duration`.
final class MonotonicTimeSource extends TimeSource {
  /// Creates the source and starts its stopwatch.
  ///
  /// There is one, `TimeSource.monotonic`; nothing else creates another.
  @internal
  MonotonicTimeSource();

  /// The stopwatch that measures the time since the origin.
  final _stopwatch = Stopwatch()..start();

  /// Reads the time passed since this source was created.
  ///
  /// Returns the elapsed time of the stopwatch.
  @override
  Duration read() => _stopwatch.elapsed;

  /// Names the source.
  @override
  String toString() => 'TimeSource(monotonic)';
}
