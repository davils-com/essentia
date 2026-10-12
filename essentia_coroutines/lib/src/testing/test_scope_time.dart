/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/testing/test_scope.dart';
import 'package:essentia_time/essentia_time.dart';

/// Kotlin's extensions on `TestScope`, moving the virtual time of the test.
extension TestScopeTime on TestScope {
  /// The virtual time passed since the test started, Kotlin's
  /// `currentTime`.
  Duration get currentTime => testScheduler.currentTime;

  /// The time source of the virtual time, Kotlin's `testTimeSource`.
  TimeSource get testTimeSource => testScheduler;

  /// Moves virtual time on by [duration], running what falls due, Kotlin's
  /// `advanceTimeBy` followed by `runCurrent`.
  ///
  /// Throws an [ArgumentError] if [duration] is negative.
  void advanceTimeBy(Duration duration) =>
      testScheduler.advanceTimeBySync(duration);

  /// Runs what is due at the current virtual time, Kotlin's `runCurrent`.
  void runCurrent() => testScheduler.runCurrentSync();

  /// Runs everything that is not background work, moving virtual time on
  /// as needed, Kotlin's `advanceUntilIdle`.
  void advanceUntilIdle() => testScheduler.advanceUntilIdleSync();
}
