/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/coroutines/cancellation_exception.dart';
import 'package:essentia/src/coroutines/coroutine_context.dart';
import 'package:essentia/src/coroutines/coroutine_context_access.dart';
import 'package:essentia/src/coroutines/coroutine_context_zone.dart';
import 'package:essentia/src/coroutines/coroutine_dispatcher.dart';
import 'package:essentia/src/coroutines/coroutine_scope.dart';
import 'package:essentia/src/coroutines/coroutine_start.dart';
import 'package:essentia/src/coroutines/dispatchers.dart';
import 'package:essentia/src/coroutines/job.dart';
import 'package:essentia/src/coroutines/scope_coroutine.dart';
import 'package:essentia/src/coroutines/supervisor_coroutine.dart';
import 'package:essentia/src/coroutines/supervisor_job.dart';

/// Runs [block] in a scope that completes once the block and every
/// coroutine it started did, Kotlin's `coroutineScope`.
///
/// The scope is a child of the current job. A failure of the block or of a
/// child cancels the rest and is thrown here, after every child stopped.
///
/// ```dart
/// final (User user, List<Order> orders) = await coroutineScope((it) async {
///   final Deferred<User> user = it.async((it) => loadUser(id));
///   final Deferred<List<Order>> orders = it.async((it) => loadOrders(id));
///   return (await user, await orders);
/// });
/// ```
///
/// Returns what [block] returns.
///
/// Throws the first failure of the block or a child.
Future<R> coroutineScope<R>(FutureOr<R> Function(CoroutineScope it) block) {
  final coroutine = ScopeCoroutine<R>(currentCoroutineContext())
    ..startCoroutine(CoroutineStart.undispatched, block);
  return coroutine.result;
}

/// Runs [block] in a scope whose children fail on their own, Kotlin's
/// `supervisorScope`.
///
/// A failing child does not cancel the scope or its siblings. The scope
/// completes once the block and every child did.
///
/// Returns what [block] returns.
///
/// Throws the failure of the block itself.
Future<R> supervisorScope<R>(FutureOr<R> Function(CoroutineScope it) block) {
  final coroutine = SupervisorCoroutine<R>(currentCoroutineContext())
    ..startCoroutine(CoroutineStart.undispatched, block);
  return coroutine.result;
}

/// Runs [block] with [context] laid over the current context and waits for
/// it and every coroutine it started, Kotlin's `withContext`.
///
/// A dispatcher in [context] that differs from the current one dispatches
/// the block; a job in [context] replaces the parent, so
/// `withContext(NonCancellable.instance, ...)` is not cancelled with the
/// caller. Otherwise a cancelled caller does not get the result of the
/// block, but its cancellation.
///
/// Returns what [block] returns.
///
/// Throws the failure of the block or a child, and a
/// [CancellationException] if the caller is cancelled.
Future<R> withContext<R>(
  CoroutineContext context,
  FutureOr<R> Function(CoroutineScope it) block,
) {
  final CoroutineContext caller = currentCoroutineContext();
  final CoroutineContext merged = caller + context;
  try {
    merged.ensureActive();
  } on CancellationException catch (cause, stackTrace) {
    return Future<R>.error(cause, stackTrace);
  }
  final CoroutineDispatcher from =
      caller.get(CoroutineDispatcher.key) ?? Dispatchers.main;
  final CoroutineDispatcher to =
      merged.get(CoroutineDispatcher.key) ?? Dispatchers.main;
  final coroutine = ScopeCoroutine<R>(merged)
    ..startCoroutine(
      from == to ? CoroutineStart.undispatched : CoroutineStart.defaultStart,
      block,
    );
  final Job? callerJob = caller.get(Job.key);
  if (callerJob == null || context.get(Job.key) != null) {
    return coroutine.result;
  }
  return coroutine.result.then((value) {
    if (callerJob.isCancelled) {
      throw callerJob.getCancellationException();
    }
    return value;
  });
}

/// A scope for the main work of a program or a user interface, Kotlin's
/// `MainScope()`: a supervisor on the event loop.
///
/// Returns the scope.
CoroutineScope mainScope() =>
    CoroutineScope(SupervisorJob() + Dispatchers.main);
