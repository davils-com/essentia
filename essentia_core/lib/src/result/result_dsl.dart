/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/result/result.dart';

/// Runs [block] and captures its outcome, Kotlin's `runCatching`.
///
/// Everything [block] throws is caught, errors included, the same way
/// Kotlin catches every `Throwable`.
///
/// Returns a [Success] carrying what [block] returns, or a [Failure]
/// carrying what it threw and the stack trace it was thrown with.
Result<T> runCatching<T>(T Function() block) {
  try {
    return Success<T>(block());
  } on Object catch (error, stackTrace) {
    return Failure<T>(error, stackTrace);
  }
}

/// Awaits [block] and captures its outcome, Kotlin's `runCatching` with a
/// suspending block.
///
/// Everything [block] throws or completes with as an error is caught.
///
/// Returns a [Success] carrying what [block] completes with, or a [Failure]
/// carrying the error and its stack trace.
Future<Result<T>> runCatchingAsync<T>(Future<T> Function() block) async {
  try {
    return Success<T>(await block());
  } on Object catch (error, stackTrace) {
    return Failure<T>(error, stackTrace);
  }
}
