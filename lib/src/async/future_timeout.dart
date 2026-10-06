/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

/// Waits for a future for a limited time, Kotlin's `withTimeoutOrNull`.
extension FutureTimeout<T> on Future<T> {
  /// Waits at most [limit] for this future.
  ///
  /// Unlike Kotlin, the work behind the future is not cancelled when the
  /// limit passes; it runs to its end and its result is dropped.
  ///
  /// Returns the value of this future, or `null` when [limit] passes first.
  ///
  /// Throws the error of this future if it fails within [limit].
  Future<T?> timeoutOrNull(Duration limit) =>
      then<T?>((value) => value).timeout(limit, onTimeout: () => null);
}
