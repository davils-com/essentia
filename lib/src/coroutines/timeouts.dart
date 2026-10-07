/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/coroutines/coroutine_context_zone.dart';
import 'package:essentia/src/coroutines/coroutine_scope.dart';
import 'package:essentia/src/coroutines/coroutine_start.dart';
import 'package:essentia/src/coroutines/timeout_cancellation_exception.dart';
import 'package:essentia/src/coroutines/timeout_coroutine.dart';

/// Runs [block] in a scope that is cancelled once [timeout] passed,
/// Kotlin's `withTimeout`.
///
/// The time is measured on the scheduler of the current context, so it is
/// virtual under `runTest`. The block and its children see the timeout as
/// their cancellation and stop at their next suspension.
///
/// Returns what [block] returns in time.
///
/// Throws a [TimeoutCancellationException] if [timeout] passes first, and
/// at once for a zero or negative [timeout].
Future<R> withTimeout<R>(
  Duration timeout,
  FutureOr<R> Function(CoroutineScope it) block,
) {
  if (timeout <= Duration.zero) {
    return Future<R>.error(
      const TimeoutCancellationException('Timed out immediately'),
    );
  }
  final coroutine = TimeoutCoroutine<R>(currentCoroutineContext(), timeout)
    ..startCoroutine(CoroutineStart.undispatched, block);
  return coroutine.result;
}

/// Runs [block] in a scope that is cancelled once [timeout] passed,
/// Kotlin's `withTimeoutOrNull`.
///
/// Only its own timeout turns into `null`; the timeout of an inner
/// `withTimeout` that the block lets escape is thrown on.
///
/// Returns what [block] returns in time, or `null` once [timeout] passed,
/// at once for a zero or negative [timeout].
Future<R?> withTimeoutOrNull<R>(
  Duration timeout,
  FutureOr<R> Function(CoroutineScope it) block,
) async {
  if (timeout <= Duration.zero) {
    return null;
  }
  final coroutine = TimeoutCoroutine<R>(currentCoroutineContext(), timeout)
    ..startCoroutine(CoroutineStart.undispatched, block);
  try {
    return await coroutine.result;
  } on TimeoutCancellationException catch (cause) {
    if (identical(cause.coroutine, coroutine)) {
      return null;
    }
    rethrow;
  }
}
