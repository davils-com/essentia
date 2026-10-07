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

/// Kotlin's extensions on `Job`.
extension JobOperations on Job {
  /// Cancels the job and waits until it is complete, Kotlin's
  /// `cancelAndJoin()`.
  ///
  /// Returns a future that completes once the job is complete.
  Future<void> cancelAndJoin([CancellationException? cause]) {
    cancel(cause);
    return join();
  }

  /// Cancels every child of the job, not the job itself, Kotlin's
  /// `cancelChildren()`.
  void cancelChildren([CancellationException? cause]) {
    for (final Job child in children.toList()) {
      child.cancel(cause);
    }
  }

  /// Throws if the job is not active, Kotlin's `ensureActive()`.
  ///
  /// Throws the [CancellationException] of the job if it is cancelling,
  /// cancelled or complete.
  void ensureActive() {
    if (!isActive) {
      throw getCancellationException();
    }
  }
}
