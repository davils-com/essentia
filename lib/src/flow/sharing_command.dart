/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// What a `SharingStarted` strategy tells the coroutine that shares a
/// stream, Kotlin's `SharingCommand`.
enum SharingCommand {
  /// Starts listening to the upstream stream, Kotlin's `START`; nothing
  /// happens if it is listened to already.
  start,

  /// Stops listening to the upstream stream, Kotlin's `STOP`.
  stop,

  /// Stops listening to the upstream stream and forgets the replay values,
  /// or resets a state flow to its initial value, Kotlin's
  /// `STOP_AND_RESET_REPLAY_CACHE`.
  stopAndResetReplayCache,
}
