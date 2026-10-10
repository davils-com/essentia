/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

part of 'local_date_test.dart';

/// A clock that always reads [time].
final class _FixedClock implements Clock {
  /// Creates the clock of [time].
  const _FixedClock(this.time);

  /// The time the clock reads.
  final Instant time;

  /// The time.
  @override
  Instant now() => time;
}
