/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// A counter as Kotlin's documentation of `StateFlow` shows it.
final class GuideCounterModel {
  /// The private mutable state.
  final MutableStateFlow<int> _counter = MutableStateFlow(0);

  /// The count, read-only.
  StateFlow<int> get counter => _counter.asStateFlow();

  /// Counts one up.
  void inc() => _counter.update((count) => count + 1);
}
