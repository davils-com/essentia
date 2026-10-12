/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// What a channel does with an element sent while its buffer is full,
/// Kotlin's `BufferOverflow`.
enum BufferOverflow {
  /// The sender waits until there is room, Kotlin's `SUSPEND`.
  suspend,

  /// The oldest buffered element is dropped to make room, Kotlin's
  /// `DROP_OLDEST`; the sender never waits.
  dropOldest,

  /// The element being sent is dropped, Kotlin's `DROP_LATEST`; the sender
  /// never waits.
  dropLatest,
}
