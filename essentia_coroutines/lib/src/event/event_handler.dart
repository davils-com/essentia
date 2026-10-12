/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/event/event.dart';
import 'package:essentia_coroutines/src/event/event_envelope.dart';

/// What a consumer runs for each envelope of type [T] it is handed.
///
/// It may finish at once or return a future; the next envelope reaches the
/// same consumer only once this one is handled.
typedef EventHandler<T extends Event> = FutureOr<void> Function(
  EventEnvelope<T> envelope,
);
