/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/time/time_source.dart';
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
