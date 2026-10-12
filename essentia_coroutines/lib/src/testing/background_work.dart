/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/context/abstract_coroutine_context_element.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_key.dart';
import 'package:meta/meta.dart';

/// Marks the context of the background scope of a test, whose timers do
/// not keep `advanceUntilIdle` going.
@internal
final class BackgroundWork with AbstractCoroutineContextElement {
  /// Creates the marker.
  const BackgroundWork();

  /// The key the marker is stored under.
  static const key = CoroutineContextKey<BackgroundWork>('BackgroundWork');

  /// The key the marker is stored under.
  @override
  CoroutineContextKey<BackgroundWork> get contextKey => key;

  /// Names the marker.
  @override
  String toString() => 'BackgroundWork';
}
