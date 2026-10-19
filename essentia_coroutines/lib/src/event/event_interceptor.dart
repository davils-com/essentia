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

import 'dart:async';

import 'package:essentia_coroutines/src/event/event.dart';
import 'package:essentia_coroutines/src/event/event_envelope.dart';

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
