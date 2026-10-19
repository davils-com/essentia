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

import 'package:essentia_coroutines/src/event/drop_reason.dart';
import 'package:essentia_coroutines/src/event/event.dart';
import 'package:essentia_coroutines/src/event/event_envelope.dart';

/// Where a bus reports what it did, so that something outside it can count
/// or log.
///
/// Essentia defines the port and implements none of it: what a counter is,
/// and where it is exported to, is the application's decision. Extend this
/// over whatever is already in the application and hand it to the bus;
/// every method does nothing unless it is overridden.
///
/// ## Rules an implementation has to keep
///
/// **Do not block and do not wait.** These are called on the dispatch
/// path. Work that takes any time belongs behind a queue the
/// implementation owns.
///
/// **Do not throw.** Nothing thrown here can reach the bus: whichever of the
/// four callbacks it came from, a failure is **caught and discarded**.
/// Taking down a publisher or abandoning a shutdown halfway is not the
/// answer, and routing it to a consumer's error handler would report a
/// failure the consumer did not have. A delivery a listener failed to record
/// is still counted as delivered and never as failed. An implementation that
/// needs to know about its own failures catches them itself.
///
/// **Do not publish from here.** Publishing from inside a notification
/// about a publication is how a loop is written by accident.
class EventListener {
  /// Creates a listener that does nothing until a method is overridden.
  const EventListener();

  /// The listener that does nothing, which is what a bus uses unless one is
  /// declared.
  static const none = EventListener();

  /// An [envelope] was accepted by a topic and is on its way.
  ///
  /// Accepted is not delivered. An envelope reported here can still be
  /// discarded, and it is reported again to [onDropped] when it is.
  void onPublished(EventEnvelope<Event> envelope) {}

  /// The [consumer], a subscription or a group, finished handling
  /// [envelope] without throwing.
  ///
  /// Called once per consumer, not once per envelope, which is what makes
  /// this the number to compare against [onPublished] when looking for a
  /// consumer that has fallen behind.
  void onDelivered(EventEnvelope<Event> envelope, String consumer) {}

  /// The [consumer] threw [failure] with [stackTrace] while handling
  /// [envelope].
  ///
  /// The envelope is not retried and not redelivered; the consumer carries
  /// on with the next one.
  void onFailed(
    EventEnvelope<Event> envelope,
    String consumer,
    Object failure,
    StackTrace stackTrace,
  ) {}

  /// An [envelope] was discarded for [reason] and will not be delivered to
  /// anybody.
  ///
  /// This is the one method worth implementing even when nothing else is:
  /// an application that does not report drops has no way of learning that
  /// a topic is losing events.
  void onDropped(EventEnvelope<Event> envelope, DropReason reason) {}
}
