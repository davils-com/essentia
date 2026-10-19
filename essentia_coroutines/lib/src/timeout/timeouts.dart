/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/context/coroutine_context_zone.dart';
import 'package:essentia_coroutines/src/coroutine/coroutine_start.dart';
import 'package:essentia_coroutines/src/scope/coroutine_scope.dart';
import 'package:essentia_coroutines/src/timeout/timeout_cancellation_exception.dart';
import 'package:essentia_coroutines/src/timeout/timeout_coroutine.dart';

/// Runs [block] in a scope that is cancelled once [timeout] passed.
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

/// Runs [block] in a scope that is cancelled once [timeout] passed.
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
