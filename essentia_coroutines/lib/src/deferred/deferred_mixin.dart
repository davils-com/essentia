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
import 'package:essentia_coroutines/src/continuation/suspension.dart';
import 'package:essentia_coroutines/src/deferred/deferred.dart';
import 'package:essentia_coroutines/src/job/job_support.dart';
import 'package:meta/meta.dart';

/// The `Deferred` and `Future` contract of a job with a result.
///
/// Every `Future` member waits through one cancellable wait, so `await`,
/// `then` and `Future.wait` all end early when the waiting code is
/// cancelled.
@internal
base mixin DeferredMixin<T> on JobSupport implements Deferred<T> {
  /// What the job produced, `null` until it did.
  ({T value})? get outcome;

  /// See [Deferred.getCompleted].
  @override
  T getCompleted() {
    if (!isCompleted) {
      throw StateError('This deferred value has not completed yet');
    }
    final AsyncError? error = completionError;
    if (error != null) {
      Error.throwWithStackTrace(error.error, error.stackTrace);
    }
    return _value();
  }

  /// See [Deferred.getCompletionExceptionOrNull].
  @override
  Object? getCompletionExceptionOrNull() {
    if (!isCompleted) {
      throw StateError('This deferred value has not completed yet');
    }
    return completionError?.error;
  }

  /// See [Future.then].
  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) => _awaited().then<R>(onValue, onError: onError);

  /// See [Future.catchError].
  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) =>
      _awaited().catchError(onError, test: test);

  /// See [Future.whenComplete].
  @override
  Future<T> whenComplete(FutureOr<void> Function() action) =>
      _awaited().whenComplete(action);

  /// See [Future.asStream].
  @override
  Stream<T> asStream() => _awaited().asStream();

  /// See [Future.timeout].
  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) =>
      _awaited().timeout(timeLimit, onTimeout: onTimeout);

  /// Waits for the result, cancellably, starting a lazily started job.
  ///
  /// Returns the value of the job.
  ///
  /// Throws the failure of the job, or the cancellation of the waiting
  /// code.
  Future<T> _awaited() {
    if (isCompleted) {
      final AsyncError? error = completionError;
      if (error != null) {
        return Future<T>.error(error.error, error.stackTrace);
      }
      return Future<T>.value(_value());
    }
    start();
    return suspendCancellableCoroutine<T>((it) {
      final Disposable registration = invokeOnCompletion(
        (cause) => _resume(it),
      );
      it.invokeOnCancellation((cause) => registration.dispose());
    });
  }

  /// Resumes [continuation] with the result of the completed job.
  void _resume(CancellableContinuation<T> continuation) {
    final AsyncError? error = completionError;
    if (error != null) {
      continuation.resumeWithException(error.error, error.stackTrace);
      return;
    }
    continuation.resume(_value());
  }

  /// The value of a job that completed normally, which always produced
  /// one.
  ///
  /// Returns the value.
  T _value() => outcome!.value;
}
