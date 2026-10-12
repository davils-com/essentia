/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_element.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_key.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/job/completion_handler.dart';
import 'package:essentia_coroutines/src/job/job_impl.dart';

/// A cancellable piece of work with a life cycle, the parent of the work it
/// starts, Kotlin's `Job`.
///
/// A job is new (only a lazily started coroutine), active, completing while
/// it waits for its children, cancelling, and finally cancelled or
/// completed:
///
/// | State | [isActive] | [isCompleted] | [isCancelled] |
/// |---|---|---|---|
/// | new | false | false | false |
/// | active | true | false | false |
/// | completing | true | false | false |
/// | cancelling | false | false | true |
/// | cancelled | false | true | true |
/// | completed | false | true | false |
///
/// Jobs form a tree. A job completes only once all its children did; a
/// cancelled job cancels its children; a child that fails cancels its
/// parent and so its siblings, unless the parent is a `SupervisorJob`. A
/// `CancellationException` is a cancellation, never a failure.
///
/// A Dart `Future` cannot be interrupted, so cancellation is cooperative:
/// waiting with `delay`, `join`, `await` on a `Deferred`, a channel, a
/// `Mutex` or a `Semaphore` ends with a [CancellationException], and long
/// work of one's own calls `ensureActive()` or `yieldNow()`.
///
/// ```dart
/// final Job job = scope.launch((it) async {
///   while (true) {
///     await refresh();
///     await delay(30.seconds);
///   }
/// });
/// await job.cancelAndJoin();
/// ```
abstract interface class Job implements CoroutineContextElement {
  /// Creates an active job without a body, a child of [parent] if given,
  /// Kotlin's `Job(parent)`.
  ///
  /// The job is a `CompletableJob`; create it as one to call `complete`.
  /// Once cancelled it completes as soon as its children did.
  factory Job([Job? parent]) = JobImpl;

  /// The key a job is stored under in a coroutine context.
  static const key = CoroutineContextKey<Job>('Job');

  /// The parent of this job, if it has one that is still waiting for it.
  Job? get parent;

  /// Whether the job is active: started, and neither cancelled nor
  /// complete.
  bool get isActive;

  /// Whether the job reached its final state, completed or cancelled.
  bool get isCompleted;

  /// Whether the job was cancelled for any reason, a failure included.
  bool get isCancelled;

  /// The children that have not completed yet.
  Iterable<Job> get children;

  /// Starts a lazily started job, Kotlin's `start()`.
  ///
  /// Returns `true` when this call started it, `false` when it was started
  /// already or is complete.
  bool start();

  /// Cancels the job and its children, Kotlin's `cancel(cause)`.
  ///
  /// [cause] says why; without one a `JobCancellationException` is used.
  /// Cancelling a job that is cancelling or complete does nothing.
  void cancel([CancellationException? cause]);

  /// Why the job is cancelled, Kotlin's `getCancellationException()`.
  ///
  /// Returns the cancellation exception, wrapping the failure of a failed
  /// job, or one saying that the job completed normally.
  ///
  /// Throws a [StateError] while the job is new or active.
  CancellationException getCancellationException();

  /// Waits until the job is complete, Kotlin's `join()`.
  ///
  /// It does not throw the failure of the job. A lazily started job is
  /// started.
  ///
  /// Returns a future that completes once the job is complete.
  ///
  /// Throws a [CancellationException] if the job of the waiting code is
  /// cancelled while it waits.
  Future<void> join();

  /// Registers [handler] to run once the job completes, Kotlin's
  /// `invokeOnCompletion`.
  ///
  /// With [onCancelling] the handler runs as soon as the job starts to be
  /// cancelled instead. A handler registered with a job that is complete,
  /// or cancelling for [onCancelling], runs at once.
  ///
  /// Returns a handle whose `dispose` removes the handler again.
  Disposable invokeOnCompletion(
    CompletionHandler handler, {
    bool onCancelling = false,
  });
}
