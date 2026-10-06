/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// A listener whose exporter fails on every delivery and that records which
/// consumers it was told failed.
final class DeliveryFailingListener extends EventListener {
  /// What every delivery notification throws.
  static const message = 'exporter is down';

  /// The consumers reported as failed.
  final failedConsumers = <String>[];

  /// Throws instead of recording [envelope] as delivered to [consumer].
  @override
  void onDelivered(EventEnvelope<Event> envelope, String consumer) {
    throw StateError(message);
  }

  /// Records [consumer] as failed with [failure] on [envelope].
  @override
  void onFailed(
    EventEnvelope<Event> envelope,
    String consumer,
    Object failure,
    StackTrace stackTrace,
  ) {
    failedConsumers.add(consumer);
  }
}
