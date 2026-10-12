/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/essentia_coroutines.dart';

/// A listener that records everything it is told, for the event tests.
final class RecordingListener extends EventListener {
  /// The envelopes reported as published.
  final published = <EventEnvelope<Event>>[];

  /// The envelopes reported as delivered, with their consumer.
  final delivered = <(EventEnvelope<Event>, String)>[];

  /// The envelopes reported as failed, with their consumer and failure.
  final failed = <(EventEnvelope<Event>, String, Object)>[];

  /// The envelopes reported as dropped, with the reason.
  final dropped = <(EventEnvelope<Event>, DropReason)>[];

  /// The reasons of every drop, in order.
  List<DropReason> get dropReasons => dropped.map((entry) => entry.$2).toList();

  /// Records [envelope] as published.
  @override
  void onPublished(EventEnvelope<Event> envelope) {
    published.add(envelope);
  }

  /// Records [envelope] as delivered to [consumer].
  @override
  void onDelivered(EventEnvelope<Event> envelope, String consumer) {
    delivered.add((envelope, consumer));
  }

  /// Records [envelope] as failed in [consumer] with [failure].
  @override
  void onFailed(
    EventEnvelope<Event> envelope,
    String consumer,
    Object failure,
    StackTrace stackTrace,
  ) {
    failed.add((envelope, consumer, failure));
  }

  /// Records [envelope] as dropped for [reason].
  @override
  void onDropped(EventEnvelope<Event> envelope, DropReason reason) {
    dropped.add((envelope, reason));
  }
}
