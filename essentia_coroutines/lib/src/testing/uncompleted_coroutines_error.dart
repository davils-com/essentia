/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Reports that the test body of `runTest`, or a coroutine it waits for,
/// did not complete in time, Kotlin's `UncompletedCoroutinesError`.
final class UncompletedCoroutinesError extends AssertionError {
  /// Creates the error with [message].
  UncompletedCoroutinesError(String super.message);

  /// Renders the error with its message.
  @override
  String toString() => 'UncompletedCoroutinesError: $message';
}
