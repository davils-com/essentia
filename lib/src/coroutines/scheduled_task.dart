/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// An action a `Scheduler` runs later, and the handle that calls it off.
abstract interface class ScheduledTask {
  /// Whether the action still waits to run.
  ///
  /// It is `false` once the action ran or the task was cancelled.
  bool get isActive;

  /// Calls the action off if it has not run yet.
  ///
  /// Cancelling a task that already ran or was cancelled does nothing.
  void cancel();
}
