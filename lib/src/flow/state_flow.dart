/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/flow/shared_flow.dart';

/// A shared flow that holds one current [value], Kotlin's `StateFlow`.
///
/// A new listener gets the current value first and then every change.
/// Changes are conflated: a listener that is slow, or paused, skips the
/// values it missed and gets only the latest one, and a value equal (`==`)
/// to the one it got before is never delivered again.
abstract interface class StateFlow<T> implements SharedFlow<T> {
  /// The current value, Kotlin's `value`.
  T get value;
}
