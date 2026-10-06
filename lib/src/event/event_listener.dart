/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/event/drop_reason.dart';
import 'package:essentia/src/event/event.dart';
import 'package:essentia/src/event/event_envelope.dart';

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
/// **Do not throw.** [onDelivered] runs on the consuming path, so a failure
/// there is routed to the topic's error handler like any other. [onPublished],
/// [onDropped] and [onFailed] are reached from `tryPublish`, from an
/// overflowing partition and from `dispose`, none of which has an error
/// handler to call, so a failure there is **caught and discarded**.
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
