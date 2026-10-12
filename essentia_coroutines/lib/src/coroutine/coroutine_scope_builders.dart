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
import 'package:essentia_coroutines/src/coroutine/coroutine_start.dart';
import 'package:essentia_coroutines/src/coroutine/deferred_coroutine.dart';
import 'package:essentia_coroutines/src/coroutine/standalone_coroutine.dart';
import 'package:essentia_coroutines/src/deferred/deferred.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/scope/context_scope.dart';
import 'package:essentia_coroutines/src/scope/coroutine_scope.dart';

/// Kotlin's coroutine builders and scope extensions.
extension CoroutineScopeBuilders on CoroutineScope {
  /// Starts [block] as a child of the scope's job, Kotlin's `launch`.
  ///
  /// [context] is laid over the scope's context, and [start] says how the
  /// body starts. A failure of the body cancels the scope, unless its job is
  /// a supervisor; a failure no parent takes over goes to the
  /// `CoroutineExceptionHandler` of the context.
  ///
  /// Returns the job of the coroutine. It is not a `Future`, so starting
  /// work that nobody waits for passes the `unawaited_futures` lint.
  Job launch(
    FutureOr<void> Function(CoroutineScope it) block, {
    CoroutineContext context = CoroutineContext.empty,
    CoroutineStart start = CoroutineStart.defaultStart,
  }) => StandaloneCoroutine(
    coroutineContext + context,
    active: start != CoroutineStart.lazy,
  )..startCoroutine(start, block);

  /// Starts [block] as a child of the scope's job and keeps its result,
  /// Kotlin's `async`.
  ///
  /// [context] is laid over the scope's context, and [start] says how the
  /// body starts. A failure stays in the deferred and is thrown to whoever
  /// awaits it; it also cancels the scope, unless its job is a supervisor.
  ///
  /// Returns the deferred result, a `Future`.
  Deferred<T> async<T>(
    FutureOr<T> Function(CoroutineScope it) block, {
    CoroutineContext context = CoroutineContext.empty,
    CoroutineStart start = CoroutineStart.defaultStart,
  }) => DeferredCoroutine<T>(
    coroutineContext + context,
    active: start != CoroutineStart.lazy,
  )..startCoroutine(start, block);

  /// Whether the scope's job is active, `true` without a job, Kotlin's
  /// `CoroutineScope.isActive`.
  bool get isActive => coroutineContext.isActive;

  /// Cancels the scope's job and every coroutine started in it, Kotlin's
  /// `CoroutineScope.cancel()`.
  ///
  /// Throws a [StateError] if the scope has no job.
  void cancel([CancellationException? cause]) {
    final Job? job = coroutineContext.get(Job.key);
    if (job == null) {
      throw StateError(
        'Scope cannot be cancelled because it does not have a job: $this',
      );
    }
    job.cancel(cause);
  }

  /// Throws if the scope's job is cancelled, Kotlin's
  /// `CoroutineScope.ensureActive()`.
  ///
  /// Throws the [CancellationException] of the job if it is cancelled.
  void ensureActive() => coroutineContext.ensureActive();

  /// A scope with [context] laid over this scope's context, Kotlin's
  /// `CoroutineScope.plus`.
  ///
  /// Returns the new scope.
  CoroutineScope operator +(CoroutineContext context) =>
      ContextScope(coroutineContext + context);
}
