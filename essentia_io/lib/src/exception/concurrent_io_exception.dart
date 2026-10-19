/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Thrown when two coroutines read, or two write, a byte channel at the
/// same time.
///
/// A channel has one reader and one writer; a second one at the same time
/// is a programming mistake, so this is an [Error].
final class ConcurrentIoException extends StateError {
  /// Creates the error for a concurrent [task], `read` or `write`.
  ConcurrentIoException(this.task) : super('Concurrent $task attempts');

  /// What was attempted twice at the same time: `read` or `write`.
  final String task;
}
