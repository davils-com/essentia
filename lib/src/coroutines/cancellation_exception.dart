/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Reports that work stopped because its job was cancelled, Kotlin's
/// `CancellationException`.
///
/// It is not a failure of the work: whoever cancelled the job asked for it.
/// Code that counts failures, retries them or records them leaves a
/// cancellation alone and passes it on, and a coroutine that ends with one
/// is cancelled, not failed.
base class CancellationException implements Exception {
  /// Creates the exception with an optional [message] saying why the job
  /// was cancelled, and the [cause] behind it.
  const CancellationException([this.message, this.cause]);

  /// Why the job was cancelled, if anybody said.
  final String? message;

  /// The failure that led to the cancellation, if there was one.
  final Object? cause;

  /// Renders the exception with its message.
  @override
  String toString() {
    final String? reason = message;
    if (reason == null) {
      return 'CancellationException';
    }
    return 'CancellationException: $reason';
  }
}
