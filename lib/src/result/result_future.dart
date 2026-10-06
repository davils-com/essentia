/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/result/result.dart';
import 'package:essentia/src/result/result_dsl.dart';

/// Captures the outcome of a future as a [Result].
extension ResultFuture<T> on Future<T> {
  /// Awaits this future and captures its outcome, Kotlin's `runCatching`
  /// around an awaited call.
  ///
  /// Returns a [Success] carrying the value this future completes with, or a
  /// [Failure] carrying its error and stack trace.
  Future<Result<T>> toResult() => runCatchingAsync<T>(() => this);
}
