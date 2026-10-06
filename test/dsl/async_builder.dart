/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

import 'async_data.dart';

/// Assembles an [AsyncData].
final class AsyncBuilder extends ValidatingBuilder<AsyncData> {
  /// How many entries the queue holds.
  var queueSize = 1024;

  /// Assembles the part.
  @override
  AsyncData assemble() => AsyncData(queueSize);
}
