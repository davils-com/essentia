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
import 'package:meta/meta.dart';

/// The zone value under which the envelope being handled travels.
const _handledEnvelopeKey = #_handledEnvelope;

/// Runs [body] as the handling of [envelope], so that anything it publishes,
/// however deep in its asynchronous work, joins the chain of that envelope.
///
/// Returns the future of [body].
@internal
Future<void> handling(
  EventEnvelope<Event> envelope,
  Future<void> Function() body,
) => runZoned(
  body,
  zoneValues: <Object?, Object?>{_handledEnvelopeKey: envelope},
);

/// The envelope whose handling the current code runs in.
///
/// Returns the envelope, or `null` outside the handling of one.
@internal
EventEnvelope<Event>? handledEnvelope() {
  final Object? value = Zone.current[_handledEnvelopeKey];
  if (value is EventEnvelope<Event>) {
    return value;
  }
  return null;
}
