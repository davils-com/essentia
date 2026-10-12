/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/coroutine/scope_coroutine.dart';
import 'package:essentia_coroutines/src/scheduler/scheduled_task.dart';
import 'package:essentia_coroutines/src/scheduler/scheduler.dart';
import 'package:essentia_coroutines/src/timeout/timeout_cancellation_exception.dart';
import 'package:meta/meta.dart';

/// The coroutine of `withTimeout`: it cancels itself with a
/// `TimeoutCancellationException` once [timeout] passed on the scheduler of
/// its context.
@internal
final class TimeoutCoroutine<T> extends ScopeCoroutine<T> {
  /// Creates the coroutine as a child of the job of [parentContext], timed
  /// out after [timeout].
  TimeoutCoroutine(super.parentContext, this.timeout) {
    final Scheduler scheduler =
        parentContext.get(Scheduler.key) ?? Scheduler.system;
    _deadline = scheduler.schedule(timeout, _timedOut);
  }

  /// How long the block may take.
  final Duration timeout;

  /// The task that cancels the coroutine once [timeout] passed.
  ScheduledTask? _deadline;

  /// Names the kind of coroutine.
  @override
  String get kind => 'TimeoutCoroutine';

  /// Calls the deadline off, then completes the result.
  @override
  void onCompletionInternal(AsyncError? error) {
    _deadline?.cancel();
    super.onCompletionInternal(error);
  }

  /// Cancels the coroutine because its time ran out.
  void _timedOut() => cancelImpl(
    TimeoutCancellationException(
      'Timed out waiting for ${timeout.inMilliseconds} ms',
      coroutine: this,
    ),
    StackTrace.current,
  );
}
