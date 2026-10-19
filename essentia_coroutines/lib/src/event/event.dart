/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
