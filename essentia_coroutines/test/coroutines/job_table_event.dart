/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// What happens to a job in the state table of the job state test.
enum JobTableEvent {
  /// `start()`.
  start,

  /// `cancel()`.
  cancel,

  /// The body returns.
  complete,

  /// The body throws the failure of the probe.
  completeExceptionally,

  /// A child completes.
  childComplete,

  /// A child fails with the failure of the probe.
  childFail,
}
