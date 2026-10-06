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

/// The asynchronous part of a sink.
@immutable
final class AsyncData implements Validatable {
  /// Creates the part with a queue of [queueSize] entries.
  const AsyncData(this.queueSize);

  /// How many entries the queue holds.
  final int queueSize;

  /// States what is wrong with the queue.
  @override
  void validate(ValidationScope scope) {
    if (queueSize <= 0) {
      scope.fail('must be greater than zero', property: 'queueSize');
    }
  }
}
