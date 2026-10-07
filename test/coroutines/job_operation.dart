/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// What the property test does to a job.
enum JobOperation {
  /// `cancel()`.
  cancel,

  /// `complete()`.
  complete,

  /// `completeExceptionally(failure)`.
  fail,
}
