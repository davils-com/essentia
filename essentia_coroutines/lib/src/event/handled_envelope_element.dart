/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/context/abstract_coroutine_context_element.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_key.dart';
import 'package:essentia_coroutines/src/event/event.dart';
import 'package:essentia_coroutines/src/event/event_envelope.dart';
import 'package:meta/meta.dart';

/// The envelope being handled, as an element of the coroutine context.
@internal
final class HandledEnvelopeElement with AbstractCoroutineContextElement {
  /// Creates the element carrying [envelope].
  const HandledEnvelopeElement(this.envelope);

  /// The key the envelope is stored under.
  static const key = CoroutineContextKey<HandledEnvelopeElement>(
    'HandledEnvelope',
  );

  /// The envelope being handled.
  final EventEnvelope<Event> envelope;

  /// The key the envelope is stored under.
  @override
  CoroutineContextKey<HandledEnvelopeElement> get contextKey => key;

  /// Renders the envelope.
  @override
  String toString() => 'HandledEnvelope(${envelope.id})';
}
