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
