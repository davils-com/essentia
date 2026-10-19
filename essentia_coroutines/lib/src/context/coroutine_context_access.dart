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

import 'package:essentia_coroutines/src/context/coroutine_context.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/job/job_operations.dart';

/// The job operations on a `CoroutineContext`.
extension CoroutineContextAccess on CoroutineContext {
  /// The job of the context.
  ///
  /// Throws a [StateError] if the context holds no job.
  Job get job {
    final Job? found = get(Job.key);
    if (found == null) {
      throw StateError('Current context does not contain a job: $this');
    }
    return found;
  }

  /// Whether the job of the context is active, `true` without a job.
  bool get isActive => get(Job.key)?.isActive ?? true;

  /// Throws if the job of the context is not active.
  ///
  /// Throws the [CancellationException] of the job if it is cancelled.
  void ensureActive() => get(Job.key)?.ensureActive();

  /// Cancels the job of the context, if it holds one.
  void cancel([CancellationException? cause]) => get(Job.key)?.cancel(cause);

  /// Cancels the children of the job of the context.
  void cancelChildren([CancellationException? cause]) =>
      get(Job.key)?.cancelChildren(cause);
}
