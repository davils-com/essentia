/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Something that happened, which a topic carries.
///
/// An event is the payload and nothing else. It has no identifier, no
/// timestamp and no place to put a correlation id, because all of that
/// belongs to the delivery rather than to the fact: the same fact
/// republished onto a second topic is the same fact, and it would be wrong
/// for it to keep the first delivery's identity. `EventEnvelope` owns that
/// half, and a subscriber that wants it reads it off the envelope.
///
/// Implementations should be immutable. A topic hands the same instance to
/// every subscriber, so an event a subscriber can mutate is one subscriber
/// changing what the others see.
///
/// A sealed hierarchy is the shape this is meant for, because it lets a
/// subscriber switch over the variant it cares about and lets the analyzer
/// say when a new variant appears:
///
/// ```dart
/// sealed class UserEvent implements Event {
///   const UserEvent(this.userId);
///   final String userId;
/// }
///
/// final class UserRegistered extends UserEvent {
///   const UserRegistered(super.userId);
/// }
///
/// final class UserDeleted extends UserEvent {
///   const UserDeleted(super.userId, this.reason);
///   final String reason;
/// }
/// ```
abstract interface class Event {}
