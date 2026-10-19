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

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/src/context/abstract_coroutine_context_element.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_key.dart';
import 'package:essentia_coroutines/src/continuation/suspension.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/job/completion_handler.dart';
import 'package:essentia_coroutines/src/job/disposable_action.dart';
import 'package:essentia_coroutines/src/job/job.dart';

/// A job that is always active and never cancelled.
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
