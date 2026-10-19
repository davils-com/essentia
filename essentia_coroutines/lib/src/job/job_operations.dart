/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/job/job.dart';

/// The operations on a `Job` built from its contract.
extension JobOperations on Job {
  /// Cancels the job and waits until it is complete.
  ///
  /// Returns a future that completes once the job is complete.
  Future<void> cancelAndJoin([CancellationException? cause]) {
    cancel(cause);
    return join();
  }

  /// Cancels every child of the job, not the job itself.
  void cancelChildren([CancellationException? cause]) {
    for (final Job child in children.toList()) {
      child.cancel(cause);
    }
  }

  /// Throws if the job is not active.
  ///
  /// Throws the [CancellationException] of the job if it is cancelling,
  /// cancelled or complete.
  void ensureActive() {
    if (!isActive) {
      throw getCancellationException();
    }
  }
}
