/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

import 'queue_config.dart';

/// Assembles a [QueueConfig].
final class QueueConfigBuilder extends ValidatingBuilder<QueueConfig> {
  /// How many entries the queue holds.
  var size = 1024;

  /// Assembles the queue.
  @override
  QueueConfig assemble() => QueueConfig(size);
}
