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

import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/job/job_impl.dart';

/// A job without a body that is completed by hand.
///
/// ```dart
/// final job = CompletableJob();
/// final scope = CoroutineScope(job);
/// scope.launch((it) => work());
/// job.complete();
/// await job.join(); // waits for the work
/// ```
abstract interface class CompletableJob implements Job {
  /// Creates an active job, a child of [parent] if given.
  factory CompletableJob([Job? parent]) = JobImpl;

  /// Completes the job once its children did.
  ///
  /// Returns `true` when this call moved the job towards completion,
  /// `false` when it was completing, cancelling or complete already.
  bool complete();

  /// Fails the job with [exception].
  ///
  /// Returns `true` when this call failed the job, `false` when it was
  /// complete already.
  bool completeExceptionally(Object exception, [StackTrace? stackTrace]);
}
