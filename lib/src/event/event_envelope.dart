/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/event/event.dart';
import 'package:essentia/src/event/event_headers.dart';
import 'package:essentia/src/identity/uuid.dart';
import 'package:meta/meta.dart';

/// One event of type [T] as it travelled, with everything the bus knows
/// about it around it.
///
/// What a subscriber receives. The [payload] is the event a publisher
/// passed; the rest is the bus saying which topic carried it, what ordered
/// it, what it was part of and what was attached to it on the way. Two
/// envelopes are equal when their [id] is, so the same event published
/// twice is two envelopes rather than one.
@immutable
final class EventEnvelope<T extends Event> {
  /// Creates the envelope [id] of [payload] on [topic].
  @internal
  const EventEnvelope({
    required this.id,
    required this.topic,
    required this.key,
    required this.correlationId,
    required this.causationId,
    required this.headers,
    required this.payload,
  });

  /// What identifies this envelope, and when it happened.
  ///
  /// A UUIDv7, so envelopes sort by it in the order they were published and
  /// [occurredAt] can be read back out of it rather than stored beside it.
  final UuidV7 id;

  /// The name of the topic that carried it.
  final String topic;

  /// What this envelope was ordered under, or `null` when it was published
  /// without a key.
  ///
  /// Envelopes sharing a key land on the same partition and reach
  /// subscribers in publish order.
  final String? key;

  /// What ties this envelope to everything else done for the same original
  /// request.
  ///
  /// Inherited by anything published while handling this one, so a whole
  /// chain of consequences carries the identifier the chain started with.
  final UuidV7 correlationId;

  /// The [id] of the envelope whose handling published this one, or `null`
  /// when nothing did.
  ///
  /// Where [correlationId] names the request, this names the immediate
  /// cause, so the two together are the difference between "part of the
  /// same story" and "happened because of that one".
  final UuidV7? causationId;

  /// What was attached to this envelope alongside its payload.
  final EventHeaders headers;

  /// The event itself, as the publisher passed it.
  final T payload;

  /// When this was published, to millisecond resolution, in UTC.
  ///
  /// Read from [id] rather than captured beside it, so that the order
  /// envelopes sort in is the order they report having happened in.
  DateTime get occurredAt => id.instant;

  /// Whether this envelope was published while handling another one.
  bool get isCaused => causationId != null;

  /// Returns this envelope typed by the narrower payload type [R], for a
  /// subscriber that listens for one variant of a sealed hierarchy.
  ///
  /// Throws a [TypeError] if the payload is not an [R].
  @internal
  EventEnvelope<R> narrowed<R extends Event>() => EventEnvelope<R>(
    id: id,
    topic: topic,
    key: key,
    correlationId: correlationId,
    causationId: causationId,
    headers: headers,
    payload: payload as R,
  );

  /// Two envelopes are equal when their identifiers are.
  @override
  bool operator ==(Object other) => other is EventEnvelope && id == other.id;

  /// The hash of the identifier.
  @override
  int get hashCode => id.hashCode;

  /// Renders the envelope with its identity, its ordering, its cause, its
  /// headers with sensitive values masked, and its payload.
  @override
  String toString() {
    final orderedUnder = key == null ? '' : ', key=$key';
    final causedBy = causationId == null ? '' : ', causationId=$causationId';
    final carried = headers.isEmpty ? '' : ', headers=$headers';
    return 'EventEnvelope(id=$id, topic=$topic$orderedUnder$causedBy'
        '$carried, payload=$payload)';
  }
}
