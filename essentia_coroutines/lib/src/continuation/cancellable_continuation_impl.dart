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
import 'package:essentia_coroutines/src/continuation/cancellable_continuation.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/job/job.dart';
import 'package:meta/meta.dart';

/// The continuation behind `suspendCancellableCoroutine`.
@internal
final class CancellableContinuationImpl<T>
    implements CancellableContinuation<T> {
  /// Creates the continuation of code running in [_job].
  CancellableContinuationImpl(this._job);

  /// The job of the waiting code, if it has one.
  final Job? _job;

  /// Completes once the continuation is resumed or cancelled.
  final _outcome = Completer<T>();

  /// The registration with the job.
  Disposable? _registration;

  /// What runs once the continuation is cancelled.
  void Function(Object? cause)? _cancellationHandler;

  /// What takes the value the cancelled waiting code cannot take any more.
  void Function(Object cause)? _onCancellation;

  /// Why the continuation was cancelled, `null` while it was not.
  Object? _cancelCause;

  /// Whether the continuation was resumed.
  var _resumed = false;

  /// Whether the continuation was cancelled.
  var _cancelled = false;

  /// See [CancellableContinuation.isActive].
  @override
  bool get isActive => !_resumed && !_cancelled;

  /// See [CancellableContinuation.isCompleted].
  @override
  bool get isCompleted => _resumed || _cancelled;

  /// See [CancellableContinuation.isCancelled].
  @override
  bool get isCancelled => _cancelled;

  /// The value the waiting code gets: the value it was resumed with, unless
  /// its job was cancelled meanwhile.
  Future<T> get result => _outcome.future.then(_deliver);

  /// Follows the job, so that cancelling it cancels the continuation.
  void install() {
    final Job? job = _job;
    if (job == null) {
      return;
    }
    _registration = job.invokeOnCompletion(onCancelling: true, (cause) {
      cancel(
        cause is CancellationException ? cause : job.getCancellationException(),
      );
    });
  }

  /// See [CancellableContinuation.resume].
  @override
  void resume(T value, {void Function(Object cause, T value)? onCancellation}) {
    if (_cancelled) {
      onCancellation?.call(
        _cancelCause ?? const CancellationException(),
        value,
      );
      return;
    }
    if (_resumed) {
      throw StateError('Already resumed');
    }
    _resumed = true;
    if (onCancellation != null) {
      _onCancellation = (cause) => onCancellation(cause, value);
    }
    _detach();
    _outcome.complete(value);
  }

  /// See [CancellableContinuation.resumeWithException].
  @override
  void resumeWithException(Object error, [StackTrace? stackTrace]) {
    if (_cancelled) {
      return;
    }
    if (_resumed) {
      throw StateError('Already resumed');
    }
    _resumed = true;
    _detach();
    _outcome.completeError(error, stackTrace);
  }

  /// See [CancellableContinuation.cancel].
  @override
  bool cancel([Object? cause]) {
    if (!isActive) {
      return false;
    }
    final Object reason =
        cause ?? const CancellationException('Continuation was cancelled');
    _cancelled = true;
    _cancelCause = reason;
    _detach();
    final void Function(Object? cause)? handler = _cancellationHandler;
    _cancellationHandler = null;
    if (handler != null) {
      try {
        handler(reason);
      } on Object catch (error, stackTrace) {
        Zone.current.handleUncaughtError(error, stackTrace);
      }
    }
    _outcome.completeError(reason, StackTrace.current);
    return true;
  }

  /// See [CancellableContinuation.invokeOnCancellation].
  @override
  void invokeOnCancellation(void Function(Object? cause) handler) {
    if (_cancellationHandler != null) {
      throw StateError('A cancellation handler is registered already');
    }
    if (_cancelled) {
      handler(_cancelCause);
      return;
    }
    if (_resumed) {
      return;
    }
    _cancellationHandler = handler;
  }

  /// Renders the state of the continuation.
  @override
  String toString() {
    if (_cancelled) {
      return 'CancellableContinuation(cancelled)';
    }
    if (_resumed) {
      return 'CancellableContinuation(resumed)';
    }
    return 'CancellableContinuation(active)';
  }

  /// Stops following the job.
  void _detach() {
    _registration?.dispose();
    _registration = null;
  }

  /// Hands [value] to the waiting code, unless its job was cancelled after
  /// the continuation was resumed, Kotlin's prompt cancellation.
  ///
  /// Returns [value].
  ///
  /// Throws the cancellation of the job if it was cancelled meanwhile.
  T _deliver(T value) {
    final Job? job = _job;
    if (job == null || !job.isCancelled) {
      return value;
    }
    final CancellationException cause = job.getCancellationException();
    _onCancellation?.call(cause);
    throw cause;
  }
}
