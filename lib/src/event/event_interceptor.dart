/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/event/event.dart';
import 'package:essentia/src/event/event_envelope.dart';

/// Something that wraps the handling of an envelope.
///
/// Where an `EventListener` is told what happened after the fact, an
/// interceptor is *around* it and decides what happens: it runs before the
/// consumer, after it, or instead of it. That is what makes it the place
/// for a tracing span, for putting the correlation identifier into the
/// logging context, for timing, and for refusing to hand an envelope to a
/// consumer at all.
///
/// ```dart
/// Future<void> tracing(
///   EventEnvelope<Event> envelope,
///   String consumer,
///   Future<void> Function() proceed,
/// ) async {
///   final Span span = tracer.start(envelope.topic, envelope.correlationId);
///   try {
///     await proceed();
///   } finally {
///     span.close();
///   }
/// }
///
/// final EventBus bus = eventBus((it) => it..intercept(tracing)..topic(users));
/// ```
///
/// An implementation calls `proceed` exactly once to let the handling
/// happen, or not at all to keep this envelope from this consumer. Anything
/// thrown out of here reaches the consumer's error handler exactly as a
/// failure of the consumer itself would.
///
/// There is no publish side, deliberately: one of the two ways to publish
/// never waits and therefore could not run an interceptor that does. What
/// publishing needs is covered without it: `EventListener.onPublished`
/// fires on both paths, a chain's correlation is carried through the zone
/// on its own, and what travels with an envelope is a parameter of the
/// publish that creates it.
typedef EventInterceptor = FutureOr<void> Function(
  EventEnvelope<Event> envelope,
  String consumer,
  Future<void> Function() proceed,
);
