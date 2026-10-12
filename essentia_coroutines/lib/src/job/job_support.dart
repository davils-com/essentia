/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/src/context/abstract_coroutine_context_element.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_key.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_zone.dart';
import 'package:essentia_coroutines/src/continuation/suspension.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/exception/suppressed_exceptions.dart';
import 'package:essentia_coroutines/src/job/completion_handler.dart';
import 'package:essentia_coroutines/src/job/completion_handler_exception.dart';
import 'package:essentia_coroutines/src/job/disposable_action.dart';
import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/job/job_cancellation_exception.dart';
import 'package:essentia_coroutines/src/job/job_handler.dart';
import 'package:essentia_coroutines/src/job/job_operations.dart';
import 'package:essentia_coroutines/src/job/job_phase.dart';
import 'package:meta/meta.dart';

/// The state machine behind every job and coroutine, Kotlin's
/// `JobSupport`.
///
/// A job finishes once its body is done and every child reached its final
/// state. The first failure cancels the job, its children and - unless the
/// parent supervises it or the job is scoped - its parent; later failures
/// are recorded as suppressed. Everything runs on one isolate, so state is
/// changed first and handlers run on a snapshot afterwards.
@internal
abstract base class JobSupport
    with AbstractCoroutineContextElement
    implements Job {
  /// Creates a job that is [active] at once, or new until started.
  JobSupport({required bool active}) : _started = active;

  /// Whether the job was started.
  bool _started;

  /// Whether the body of the job is done.
  var _bodyDone = false;

  /// The first reason the job was cancelled for, `null` while it is not
  /// cancelled.
  AsyncError? _rootCause;

  /// Every failure and cancellation recorded, the root cause first.
  final _exceptions = <AsyncError>[];

  /// Whether the job reached its final state.
  var _final = false;

  /// What the job finally ended with, `null` for a normal completion.
  AsyncError? _finalError;

  /// The children that have not completed yet.
  final _children = <JobSupport>{};

  /// The completion handlers, in registration order.
  var _handlers = <JobHandler>[];

  /// The parent this job is attached to, if it is a job of this library.
  JobSupport? _parent;

  /// The parent this job follows, whatever kind of job it is.
  Job? _parentJob;

  /// The registration with a parent of another kind.
  Disposable? _parentHandle;

  /// The key every job is stored under.
  @override
  CoroutineContextKey<Job> get contextKey => Job.key;

  /// The parent this job follows until it completes.
  @override
  Job? get parent => _parentJob;

  /// Whether the job is started and neither cancelled nor complete.
  @override
  bool get isActive => _started && _rootCause == null && !_final;

  /// Whether the job reached its final state.
  @override
  bool get isCompleted => _final;

  /// Whether the job was cancelled or failed.
  @override
  bool get isCancelled => _rootCause != null;

  /// The children that have not completed yet.
  @override
  Iterable<Job> get children => List<Job>.unmodifiable(_children);

  /// What the job finally ended with: `null` while it runs or after a
  /// normal completion.
  @internal
  AsyncError? get completionError => _finalError;

  /// The parent this job is attached to, if it is a job of this library.
  @protected
  JobSupport? get parentSupport => _parent;

  /// Whether the body of the job is done.
  @protected
  bool get isBodyDone => _bodyDone;

  /// Whether cancelling the job also finishes its body, because it has
  /// none.
  @protected
  bool get onCancelComplete => false;

  /// Whether a failure of the job is thrown to whoever waits for it instead
  /// of being passed to its parent.
  @protected
  bool get isScopedCoroutine => false;

  /// Whether the job takes over the failures of its children.
  @protected
  bool get handlesException => true;

  /// The name the job is rendered with.
  @protected
  String get debugName => 'Job';

  /// The state the job is in.
  JobPhase get _phase {
    if (_final) {
      return _rootCause == null ? JobPhase.completed : JobPhase.cancelled;
    }
    if (_rootCause != null) {
      return JobPhase.cancelling;
    }
    if (!_started) {
      return JobPhase.fresh;
    }
    return _bodyDone ? JobPhase.completing : JobPhase.active;
  }

  /// Attaches the job to [parent], so that it is cancelled with it and the
  /// parent waits for it.
  @protected
  void initParentJob(Job? parent) {
    if (parent == null) {
      return;
    }
    parent.start();
    if (parent is JobSupport) {
      _parent = parent;
      _parentJob = parent;
      if (!parent._attachChild(this)) {
        _parent = null;
        _parentJob = null;
      }
      return;
    }
    _parentJob = parent;
    _parentHandle = parent.invokeOnCompletion(onCancelling: true, (cause) {
      if (cause == null) {
        return;
      }
      parentCancelled(_asCancellation(AsyncError(cause, StackTrace.empty)));
    });
  }

  /// Starts a lazily started job.
  ///
  /// Returns whether this call started it.
  @override
  bool start() {
    if (_started || _final) {
      return false;
    }
    _started = true;
    onStart();
    return true;
  }

  /// Cancels the job with [cause], or a `JobCancellationException`.
  @override
  void cancel([CancellationException? cause]) {
    cancelImpl(
      cause ?? JobCancellationException('Job was cancelled', job: this),
      StackTrace.current,
    );
  }

  /// Why the job is cancelled.
  ///
  /// Returns the cancellation exception.
  ///
  /// Throws a [StateError] while the job is new or active.
  @override
  CancellationException getCancellationException() {
    if (_final) {
      final AsyncError? error = _finalError;
      if (error == null) {
        return JobCancellationException(
          'Job has completed normally',
          job: this,
        );
      }
      return _asCancellation(error);
    }
    final AsyncError? root = _rootCause;
    if (root != null) {
      return _asCancellation(root);
    }
    throw StateError('Job is still new or active: $this');
  }

  /// Waits until the job is complete.
  ///
  /// Returns a future that completes once it is.
  @override
  Future<void> join() {
    if (_final) {
      try {
        currentCoroutineContext().get(Job.key)?.ensureActive();
      } on CancellationException catch (cause, stackTrace) {
        return Future<void>.error(cause, stackTrace);
      }
      return Future<void>.value();
    }
    start();
    return suspendCancellableCoroutine<void>((it) {
      final Disposable registration = invokeOnCompletion(
        (cause) => it.resume(null),
      );
      it.invokeOnCancellation((cause) => registration.dispose());
    });
  }

  /// Registers [handler] to run on completion, or when the job starts to be
  /// cancelled with [onCancelling].
  ///
  /// Returns the handle that removes it.
  @override
  Disposable invokeOnCompletion(
    CompletionHandler handler, {
    bool onCancelling = false,
  }) {
    if (_final) {
      handler(_finalError?.error);
      return DisposableAction.none;
    }
    final AsyncError? root = _rootCause;
    if (onCancelling && root != null) {
      handler(root.error);
      return DisposableAction.none;
    }
    final node = JobHandler(handler, onCancelling: onCancelling);
    _handlers = <JobHandler>[..._handlers, node];
    return DisposableAction(() {
      node.done = true;
      _handlers = <JobHandler>[
        for (final JobHandler registered in _handlers)
          if (!identical(registered, node)) registered,
      ];
    });
  }

  /// Renders the kind of job and its state.
  @override
  String toString() {
    final String state = switch (_phase) {
      JobPhase.fresh => 'new',
      JobPhase.active => 'active',
      JobPhase.completing => 'completing',
      JobPhase.cancelling => 'cancelling',
      JobPhase.cancelled => 'cancelled',
      JobPhase.completed => 'completed',
    };
    return '$debugName($state)';
  }

  /// Runs once a lazily started job is started.
  @protected
  void onStart() {}

  /// Runs once the job reached its final state, with what it ended with:
  /// `null` for a normal completion.
  @protected
  void onCompletionInternal(AsyncError? error) {}

  /// Reports a failure the job and its parent did not take over.
  ///
  /// Returns whether the failure was reported.
  @protected
  bool handleJobException(Object error, StackTrace stackTrace) => false;

  /// Reports that a completion handler threw [error].
  @protected
  void handleOnCompletionException(Object error, StackTrace stackTrace) =>
      Zone.current.handleUncaughtError(
        CompletionHandlerException(error, stackTrace),
        stackTrace,
      );

  /// Cancels the job because its parent is cancelled for [cause].
  @protected
  void parentCancelled(CancellationException cause) =>
      cancelImpl(cause, StackTrace.empty);

  /// Takes over the failure [cause] of a child.
  ///
  /// Returns whether the job takes it over, so the child does not report
  /// it itself.
  @protected
  bool childCancelled(Object cause, StackTrace stackTrace) {
    if (cause is CancellationException) {
      return true;
    }
    return cancelImpl(cause, stackTrace) && handlesException;
  }

  /// Cancels or fails the job with [cause].
  ///
  /// Returns `false` when the job is complete already.
  @protected
  bool cancelImpl(Object cause, StackTrace stackTrace) {
    if (_final) {
      return false;
    }
    final error = AsyncError(cause, stackTrace);
    if (_rootCause != null) {
      _addException(error);
      return true;
    }
    _rootCause = error;
    _exceptions.add(error);
    if (!_started) {
      _started = true;
      _bodyDone = true;
    }
    if (onCancelComplete) {
      _bodyDone = true;
    }
    _notifyCancelling(error);
    _tryFinalize();
    return true;
  }

  /// Marks the body of the job as done.
  @protected
  void completeBody() {
    if (_final) {
      return;
    }
    _bodyDone = true;
    _tryFinalize();
  }

  /// Marks the body of the job as failed with [error].
  @protected
  void failBody(Object error, StackTrace stackTrace) {
    if (_final) {
      return;
    }
    _bodyDone = true;
    if (_rootCause == null) {
      cancelImpl(error, stackTrace);
      return;
    }
    _addException(AsyncError(error, stackTrace));
    _tryFinalize();
  }

  /// Records [error] beside the root cause, unless it is recorded already.
  void _addException(AsyncError error) {
    if (_exceptions.any((known) => identical(known.error, error.error))) {
      return;
    }
    _exceptions.add(error);
  }

  /// Attaches [child], cancelling it at once if this job is cancelled.
  ///
  /// Returns `false` when this job is complete and does not take children
  /// any more.
  bool _attachChild(JobSupport child) {
    if (_final) {
      final AsyncError? error = _finalError;
      if (error != null) {
        child.parentCancelled(_asCancellation(error));
      }
      return false;
    }
    _children.add(child);
    final AsyncError? root = _rootCause;
    if (root != null) {
      child.parentCancelled(_asCancellation(root));
    }
    return true;
  }

  /// Notes that [child] reached its final state.
  void _childCompleted(JobSupport child) {
    _children.remove(child);
    _tryFinalize();
  }

  /// Runs the cancelling handlers, cancels the children and tells the
  /// parent, once the job starts to be cancelled for [root].
  void _notifyCancelling(AsyncError root) {
    for (final JobHandler handler in _handlers) {
      if (handler.onCancelling && !handler.done) {
        handler.done = true;
        _invoke(handler, root.error);
      }
    }
    final CancellationException cause = _asCancellation(root);
    for (final child in List<JobSupport>.of(_children)) {
      child.parentCancelled(cause);
    }
    _cancelParent(root);
  }

  /// Tells the parent about [error].
  ///
  /// Returns whether the failure is taken care of without reporting it
  /// here: it is a cancellation, the job is scoped, or the parent took it
  /// over.
  bool _cancelParent(AsyncError error) {
    if (isScopedCoroutine) {
      return true;
    }
    final isCancellation = error.error is CancellationException;
    final JobSupport? parent = _parent;
    if (parent == null) {
      return isCancellation;
    }
    return parent.childCancelled(error.error, error.stackTrace) ||
        isCancellation;
  }

  /// Moves the job to its final state once its body is done and every
  /// child completed.
  void _tryFinalize() {
    if (_final || !_bodyDone || _children.isNotEmpty) {
      return;
    }
    _final = true;
    final AsyncError? error = _rootCause == null ? null : _finalCause();
    _finalError = error;
    if (error != null &&
        error.error is! CancellationException &&
        !_cancelParent(error)) {
      handleJobException(error.error, error.stackTrace);
    }
    onCompletionInternal(error);
    final List<JobHandler> handlers = _handlers;
    _handlers = <JobHandler>[];
    for (final handler in handlers) {
      if (!handler.done) {
        handler.done = true;
        _invoke(handler, error?.error);
      }
    }
    final JobSupport? parent = _parent;
    _parent = null;
    _parentJob = null;
    _parentHandle?.dispose();
    _parentHandle = null;
    parent?._childCompleted(this);
  }

  /// Picks what the job ends with: the first failure, or the first
  /// cancellation when nothing failed, and records the other failures as
  /// suppressed.
  ///
  /// Returns the final cause.
  AsyncError _finalCause() {
    final AsyncError root = _exceptions.firstWhere(
      (recorded) => recorded.error is! CancellationException,
      orElse: () => _exceptions.first,
    );
    for (final AsyncError recorded in _exceptions) {
      if (recorded.error is! CancellationException) {
        addSuppressed(root.error, recorded.error);
      }
    }
    return root;
  }

  /// Runs [handler] with [cause], reporting what it throws.
  void _invoke(JobHandler handler, Object? cause) {
    try {
      handler.handler(cause);
    } on Object catch (error, stackTrace) {
      handleOnCompletionException(error, stackTrace);
    }
  }

  /// The cancellation [error] stands for: itself when it is one, otherwise
  /// a `JobCancellationException` caused by it.
  ///
  /// Returns the cancellation exception.
  CancellationException _asCancellation(AsyncError error) {
    final Object cause = error.error;
    if (cause is CancellationException) {
      return cause;
    }
    return JobCancellationException(
      'Job was cancelled',
      job: this,
      cause: cause,
    );
  }
}
