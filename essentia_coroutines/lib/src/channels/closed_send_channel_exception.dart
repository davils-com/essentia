/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Thrown by a send to a channel that was closed without a cause, Kotlin's
/// `ClosedSendChannelException`.
///
/// Like Kotlin's, it is a programming mistake - an `IllegalStateException`
/// there, a [StateError] here: a sender that may outlive the channel checks
/// `isClosedForSend` or uses `trySend`.
final class ClosedSendChannelException extends StateError {
  /// Creates the exception with [message].
  ClosedSendChannelException([super.message = 'Channel was closed']);

  /// Renders the message.
  @override
  String toString() => 'ClosedSendChannelException: $message';
}
