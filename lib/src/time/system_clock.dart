/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/time/clock.dart';
import 'package:essentia/src/time/instant.dart';
import 'package:meta/meta.dart';

/// The clock behind `Clock.system`, which reads `DateTime.now()`.
final class SystemClock implements Clock {
  /// Creates the system clock.
  ///
  /// There is one, `Clock.system`; nothing else creates another.
  @internal
  const SystemClock();

  /// Reads the time of the system.
  ///
  /// Returns the moment it is now.
  @override
  Instant now() => Instant.fromDateTime(DateTime.now());

  /// Names the clock.
  @override
  String toString() => 'Clock(system)';
}
