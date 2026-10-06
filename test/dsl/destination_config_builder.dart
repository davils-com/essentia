/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

import 'destination_config.dart';
import 'queue_config.dart';
import 'queue_config_builder.dart';

/// Assembles a [DestinationConfig].
final class DestinationConfigBuilder
    extends ValidatingBuilder<DestinationConfig> {
  /// The name of the destination.
  var name = '';

  /// The queue configured so far.
  QueueConfig? _queue;

  /// Makes the destination asynchronous, configured by [block].
  void async(void Function(QueueConfigBuilder it) block) {
    _queue = nested<QueueConfig, QueueConfigBuilder>(
      QueueConfigBuilder(),
      'queue',
      block,
    );
  }

  /// Assembles the destination.
  @override
  DestinationConfig assemble() => DestinationConfig(name, _queue);
}
