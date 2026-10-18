/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

/// A [Disposable] whose release fails.
final class FailingResource implements Disposable {
  /// How often the release was attempted.
  var attempts = 0;

  /// Attempts the release and fails.
  @override
  void dispose() {
    attempts++;
    throw StateError('release failed');
  }
}
