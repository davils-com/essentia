/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/essentia_coroutines.dart';

/// A listener whose exporter is down, so that every notification throws.
final class BrokenExporterListener extends EventListener {
  /// Creates the listener.
  const BrokenExporterListener();

  /// What every notification throws.
  static const message = 'exporter is down';

  /// Throws instead of recording [envelope] as published.
  @override
  void onPublished(EventEnvelope<Event> envelope) {
    throw StateError(message);
  }

  /// Throws instead of recording [envelope] as delivered to [consumer].
  @override
  void onDelivered(EventEnvelope<Event> envelope, String consumer) {
    throw StateError(message);
  }

  /// Throws instead of recording [envelope] as failed in [consumer] with
  /// [failure] and [stackTrace].
  @override
  void onFailed(
    EventEnvelope<Event> envelope,
    String consumer,
    Object failure,
    StackTrace stackTrace,
  ) {
    throw StateError(message);
  }

  /// Throws instead of recording [envelope] as dropped for [reason].
  @override
  void onDropped(EventEnvelope<Event> envelope, DropReason reason) {
    throw StateError(message);
  }
}
