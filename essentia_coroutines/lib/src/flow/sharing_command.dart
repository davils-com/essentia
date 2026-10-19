/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// What a `SharingStarted` strategy tells the coroutine that shares a
/// stream.
enum SharingCommand {
  /// Starts listening to the upstream stream; nothing happens if it is
  /// listened to already.
  start,

  /// Stops listening to the upstream stream.
  stop,

  /// Stops listening to the upstream stream and forgets the replay values,
  /// or resets a state flow to its initial value.
  stopAndResetReplayCache,
}
