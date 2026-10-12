/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/context/coroutine_context.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/job/job_operations.dart';

/// Kotlin's job extensions on `CoroutineContext`.
extension CoroutineContextAccess on CoroutineContext {
  /// The job of the context, Kotlin's `CoroutineContext.job`.
  ///
  /// Throws a [StateError] if the context holds no job.
  Job get job {
    final Job? found = get(Job.key);
    if (found == null) {
      throw StateError('Current context does not contain a job: $this');
    }
    return found;
  }

  /// Whether the job of the context is active, `true` without a job,
  /// Kotlin's `CoroutineContext.isActive`.
  bool get isActive => get(Job.key)?.isActive ?? true;

  /// Throws if the job of the context is not active, Kotlin's
  /// `CoroutineContext.ensureActive()`.
  ///
  /// Throws the [CancellationException] of the job if it is cancelled.
  void ensureActive() => get(Job.key)?.ensureActive();

  /// Cancels the job of the context, if it holds one, Kotlin's
  /// `CoroutineContext.cancel()`.
  void cancel([CancellationException? cause]) => get(Job.key)?.cancel(cause);

  /// Cancels the children of the job of the context, Kotlin's
  /// `CoroutineContext.cancelChildren()`.
  void cancelChildren([CancellationException? cause]) =>
      get(Job.key)?.cancelChildren(cause);
}
