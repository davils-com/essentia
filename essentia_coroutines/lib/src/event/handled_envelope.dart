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
