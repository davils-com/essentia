/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:meta/meta.dart';

/// The queue of an asynchronous destination.
@immutable
final class QueueConfig implements Validatable {
  /// Creates the queue holding [size] entries.
  const QueueConfig(this.size);

  /// How many entries the queue holds.
  final int size;

  /// States what is wrong with the queue.
  @override
  void validate(ValidationScope scope) {
    if (size <= 0) {
      scope.fail("'$size' must be greater than zero", property: 'size');
    }
  }
}
