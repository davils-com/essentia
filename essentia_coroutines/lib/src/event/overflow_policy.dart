/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// What a topic does when a partition's buffer is full and somebody
/// publishes anyway.
///
/// This governs the publish that cannot wait. A publisher that can wait
/// waits until there is room, whatever this says, because the caller having
/// chosen to wait is a stronger statement than the topic's default.
///
/// Whichever envelope is discarded is reported to the bus's listener with
/// the reason, so a saturated topic is loud rather than quiet. Losing
/// events without saying so is the failure this type exists to prevent.
enum OverflowPolicy {
  /// Nothing is discarded; a publisher that cannot wait is refused instead.
  ///
  /// The only policy under which a topic never loses an event. A publisher
  /// that waits gets room; one that does not is told it was not accepted
  /// and decides for itself.
  suspend,

  /// The event waiting longest is discarded to make room for the new one.
  ///
  /// For a topic whose subscribers care about the current state rather than
  /// the whole history: a progress reading, a metric, a position.
  dropOldest,

  /// The new event is discarded and what is buffered is left alone.
  ///
  /// For a topic whose events are each worth the same and where finishing
  /// the backlog matters more than accepting more of it.
  dropLatest,
}
