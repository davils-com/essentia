/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'guide_counter.dart';

/// A resource of the cancellation and timeout examples that counts how many are
/// open.
final class GuideResource {
  /// Opens the resource.
  GuideResource(this.counter) {
    counter.open++;
  }

  /// The counter of open resources.
  final GuideCounter counter;

  /// Closes the resource.
  void close() => counter.open--;
}
