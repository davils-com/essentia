/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:meta/meta.dart';

import 'queue_config.dart';

/// One destination of a pipeline.
@immutable
final class DestinationConfig implements Validatable {
  /// Creates the destination [name], queued when [queue] is given.
  const DestinationConfig(this.name, this.queue);

  /// The name of the destination.
  final String name;

  /// The queue, or `null` for a synchronous destination.
  final QueueConfig? queue;

  /// States what is wrong with the destination.
  @override
  void validate(ValidationScope scope) {
    if (name.trim().isEmpty) {
      scope.fail('is required but was not set', property: 'name');
    }
  }
}
