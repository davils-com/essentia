/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_time/essentia_time.dart';

/// A clock that always reads [time].
final class FixedClock implements Clock {
  /// Creates the clock of [time].
  const FixedClock(this.time);

  /// The time the clock reads.
  final Instant time;

  /// The time.
  @override
  Instant now() => time;
}
