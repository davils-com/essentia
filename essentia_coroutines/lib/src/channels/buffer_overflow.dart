/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// What a channel does with an element sent while its buffer is full.
enum BufferOverflow {
  /// The sender waits until there is room.
  suspend,

  /// The oldest buffered element is dropped to make room; the sender never
  /// waits.
  dropOldest,

  /// The element being sent is dropped; the sender never waits.
  dropLatest,
}
