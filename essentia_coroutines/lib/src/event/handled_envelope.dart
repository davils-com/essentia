/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/context/coroutine_context_zone.dart';
import 'package:essentia_coroutines/src/event/event.dart';
import 'package:essentia_coroutines/src/event/event_envelope.dart';
import 'package:essentia_coroutines/src/event/handled_envelope_element.dart';
import 'package:meta/meta.dart';

/// Runs [body] as the handling of [envelope], so that anything it publishes,
/// however deep in its asynchronous work, joins the chain of that envelope.
///
/// Returns the future of [body].
@internal
Future<void> handling(
  EventEnvelope<Event> envelope,
  Future<void> Function() body,
) => runWithContext(HandledEnvelopeElement(envelope), body);

/// The envelope whose handling the current code runs in.
///
/// Returns the envelope, or `null` outside the handling of one.
@internal
EventEnvelope<Event>? handledEnvelope() =>
    currentCoroutineContext().get(HandledEnvelopeElement.key)?.envelope;
