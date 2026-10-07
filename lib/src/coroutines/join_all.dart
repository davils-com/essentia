/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/coroutines/cancellation_exception.dart';
import 'package:essentia/src/coroutines/job.dart';

/// Kotlin's `joinAll` on a collection of jobs.
extension JoinAll on Iterable<Job> {
  /// Waits until every job is complete, one after another, Kotlin's
  /// `joinAll()`.
  ///
  /// Returns a future that completes once all are.
  ///
  /// Throws a [CancellationException] if the waiting code is cancelled.
  Future<void> joinAll() async {
    for (final Job job in toList()) {
      await job.join();
    }
  }
}
