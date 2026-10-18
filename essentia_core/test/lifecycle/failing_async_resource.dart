/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

/// A [DisposableAsync] whose teardown fails.
final class FailingAsyncResource implements DisposableAsync {
  /// How often the teardown was attempted.
  var attempts = 0;

  /// Attempts the teardown and fails.
  @override
  Future<void> dispose() {
    attempts++;
    return Future<void>.error(StateError('teardown failed'));
  }
}
