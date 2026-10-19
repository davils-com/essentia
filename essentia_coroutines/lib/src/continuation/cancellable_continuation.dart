/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';

/// The handle a suspended piece of work is resumed through.
///
/// `suspendCancellableCoroutine` hands it to the code that registers the
/// wait. Exactly one of [resume], [resumeWithException] and [cancel] takes
/// effect; the job of the waiting code being cancelled cancels it.
abstract interface class CancellableContinuation<T> {
  /// Whether the continuation still waits.
  bool get isActive;

  /// Whether the continuation was resumed or cancelled.
  bool get isCompleted;

  /// Whether the continuation was cancelled.
  bool get isCancelled;

  /// Resumes the waiting code with [value].
  ///
  /// When the continuation was cancelled already, or the waiting code is
  /// cancelled before it can take [value], [onCancellation] receives the value
  /// so it is never lost.
  ///
  /// Throws a [StateError] if the continuation was resumed already.
  void resume(T value, {void Function(Object cause, T value)? onCancellation});

  /// Resumes the waiting code with [error].
  ///
  /// Throws a [StateError] if the continuation was resumed already.
  void resumeWithException(Object error, [StackTrace? stackTrace]);

  /// Cancels the continuation, so the waiting code ends with [cause] or a
  /// [CancellationException].
  ///
  /// Returns `true` when this call cancelled it.
  bool cancel([Object? cause]);

  /// Registers [handler] to run once the continuation is cancelled; it runs at
  /// once when it is cancelled already, and never when it is resumed.
  ///
  /// Throws a [StateError] if a handler is registered already.
  void invokeOnCancellation(void Function(Object? cause) handler);
}
