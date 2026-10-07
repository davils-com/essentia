/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/coroutines/abstract_coroutine_context_element.dart';
import 'package:essentia/src/coroutines/cancellation_exception.dart';
import 'package:essentia/src/coroutines/completion_handler.dart';
import 'package:essentia/src/coroutines/coroutine_context_key.dart';
import 'package:essentia/src/coroutines/disposable_action.dart';
import 'package:essentia/src/coroutines/job.dart';
import 'package:essentia/src/coroutines/suspension.dart';
import 'package:essentia/src/lifecycle/disposable.dart';

/// A job that is always active and never cancelled, Kotlin's
/// `NonCancellable`.
///
/// Work run with `withContext(NonCancellable.instance, ...)` is not
/// cancelled with its caller, which suits clean-up that has to finish, such
/// as giving back a permit in a `finally`.
///
/// ```dart
/// try {
///   await work();
/// } finally {
///   await withContext(NonCancellable.instance, (it) => release());
/// }
/// ```
final class NonCancellable with AbstractCoroutineContextElement implements Job {
  /// Creates the job; there is one, [instance].
  const NonCancellable._();

  /// The job that is never cancelled.
  static const instance = NonCancellable._();

  /// The key every job is stored under.
  @override
  CoroutineContextKey<Job> get contextKey => Job.key;

  /// It has no parent.
  @override
  Job? get parent => null;

  /// It is always active.
  @override
  bool get isActive => true;

  /// It never completes.
  @override
  bool get isCompleted => false;

  /// It is never cancelled.
  @override
  bool get isCancelled => false;

  /// It tracks no children.
  @override
  Iterable<Job> get children => const <Job>[];

  /// It is always started.
  ///
  /// Returns `false`.
  @override
  bool start() => false;

  /// It cannot be cancelled; this does nothing.
  @override
  void cancel([CancellationException? cause]) {}

  /// It is never cancelled.
  ///
  /// Throws a [StateError].
  @override
  CancellationException getCancellationException() =>
      throw StateError('This job is always active');

  /// It never completes, so this waits until the waiting code is
  /// cancelled.
  ///
  /// Returns a future that never completes normally.
  @override
  Future<void> join() => awaitCancellation();

  /// It never completes, so [handler] never runs.
  ///
  /// Returns a handle that does nothing.
  @override
  Disposable invokeOnCompletion(
    CompletionHandler handler, {
    bool onCancelling = false,
  }) => DisposableAction.none;

  /// Names the job.
  @override
  String toString() => 'NonCancellable';
}
