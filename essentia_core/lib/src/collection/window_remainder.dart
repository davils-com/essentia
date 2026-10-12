/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// What a windowing operation does with the elements at the end that do
/// not fill a whole window.
enum WindowRemainder {
  /// The last, partial windows are left out, so every window has the full
  /// size. Kotlin's default, `partialWindows = false`.
  drop,

  /// The last, partial windows are kept, each smaller than the one before.
  /// Kotlin's `partialWindows = true`.
  keep;

  /// Whether windows smaller than the requested size are kept.
  bool get keepsPartialWindows => this == keep;
}
