/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Thrown by a receive from a channel that was closed without a cause and holds
/// nothing more.
///
/// It is a [StateError]: a receiver that expects the end of the channel uses
/// `receiveCatching` or `consumeEach` instead.
final class ClosedReceiveChannelException extends StateError {
  /// Creates the exception with [message].
  ClosedReceiveChannelException([super.message = 'Channel was closed']);

  /// Renders the message.
  @override
  String toString() => 'ClosedReceiveChannelException: $message';
}
