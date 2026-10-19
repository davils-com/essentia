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
