/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/context/coroutine_context.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_access.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_zone.dart';
import 'package:essentia_coroutines/src/continuation/cancellable_continuation.dart';
import 'package:essentia_coroutines/src/continuation/cancellable_continuation_impl.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/scheduler/scheduler.dart';

/// Waits until [block] resumes the continuation it is handed, or the job of the
/// current code is cancelled.
///
/// This is the building block of every cancellable wait: register the wait
/// in [block], resume the continuation once it is over, and undo the
/// registration in `invokeOnCancellation`.
///
/// ```dart
/// Future<void> sleep(Duration duration) =>
///     suspendCancellableCoroutine<void>((it) {
///       final timer = Timer(duration, () => it.resume(null));
///       it.invokeOnCancellation((cause) => timer.cancel());
///     });
/// ```
///
/// A value that arrives after the job was cancelled is not delivered; the
/// waiting code ends with the cancellation instead and the value goes to
/// the `onCancellation` callback of `resume`.
///
/// Returns the value the continuation is resumed with.
///
/// Throws a [CancellationException] if the job is cancelled first, and the
/// error the continuation is resumed with.
Future<T> suspendCancellableCoroutine<T>(
  void Function(CancellableContinuation<T> it) block,
) {
  final continuation = CancellableContinuationImpl<T>(
    currentCoroutineContext().get(Job.key),
  )..install();
  try {
    block(continuation);
  } on Object catch (error, stackTrace) {
    if (!continuation.isActive) {
      return Future<T>.error(error, stackTrace);
    }
    continuation.resumeWithException(error, stackTrace);
  }
  return continuation.result;
}

/// Waits for [duration] on the scheduler of the current context.
///
/// The scheduler is `Scheduler.current`: the one in the context, or the
/// system scheduler. The wait is cancellable, and a zero or negative
/// [duration] does not wait at all.
///
/// Returns a future that completes once [duration] has passed.
///
/// Throws a [CancellationException] if the current job is cancelled.
Future<void> delay(Duration duration) => Scheduler.current.delay(duration);

/// Lets other work run before the current code goes on.
///
/// The name avoids `yield`, a reserved word in Dart.
///
/// It waits for a zero delay timer, so microtasks, timers and input that
/// are due run first. Long work of one's own calls it between steps to stay
/// cancellable and fair.
///
/// Returns a future that completes once the other work had its turn.
///
/// Throws a [CancellationException] if the current job is cancelled.
Future<void> yieldNow() {
  final CoroutineContext context = currentCoroutineContext();
  if (!context.isActive) {
    return Future<void>.error(context.job.getCancellationException());
  }
  return suspendCancellableCoroutine<void>((it) {
    final timer = Timer(Duration.zero, () => it.resume(null));
    it.invokeOnCancellation((cause) => timer.cancel());
  });
}

/// Waits until the current job is cancelled.
///
/// Returns a future that never completes normally.
///
/// Throws the [CancellationException] of the job once it is cancelled.
Future<Never> awaitCancellation() =>
    suspendCancellableCoroutine<Never>((it) {});

/// Throws if the job of the current code is cancelled.
///
/// Code outside every job is never cancelled and passes.
///
/// Throws a [CancellationException] if the current job is cancelled.
void ensureActive() => currentCoroutineContext().ensureActive();

/// Whether [error] is the cancellation of the current code itself: a
/// [CancellationException] thrown while the job of the current code is
/// cancelled.
///
/// A component that turns failures into results or fallbacks passes such
/// an error on, because its caller asked to stop; a cancellation that
/// reaches it from work it waited for, while it is not cancelled itself,
/// is an ordinary outcome.
///
/// ```dart
/// try {
///   return await call();
/// } on Object catch (error) {
///   if (isCurrentCancellation(error)) {
///     rethrow;
///   }
///   return fallback(error);
/// }
/// ```
///
/// Returns `true` for a cancellation while the current job is cancelled.
bool isCurrentCancellation(Object error) =>
    error is CancellationException &&
    (currentCoroutineContext().get(Job.key)?.isCancelled ?? false);
