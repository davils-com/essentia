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

import 'package:essentia_coroutines/src/job/completable_job.dart';
import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/job/job_support.dart';
import 'package:meta/meta.dart';

/// The job behind `Job()` and `CompletableJob()`: a job without a body,
/// completed by hand.
@internal
base class JobImpl extends JobSupport implements CompletableJob {
  /// Creates an active job, a child of [parent] if given.
  JobImpl([Job? parent]) : super(active: true) {
    initParentJob(parent);
  }

  /// A job without a body is done with it once cancelled.
  @override
  bool get onCancelComplete => true;

  /// A job takes over the failures of its children only when one of its
  /// ancestors is a coroutine that does.
  @override
  bool get handlesException {
    JobSupport? ancestor = parentSupport;
    while (ancestor is JobImpl) {
      ancestor = ancestor.parentSupport;
    }
    return ancestor?.handlesException ?? false;
  }

  /// Completes the job once its children did.
  ///
  /// Returns whether this call moved it towards completion.
  @override
  bool complete() {
    if (!isActive || isBodyDone) {
      return false;
    }
    completeBody();
    return true;
  }

  /// Fails the job with [exception].
  ///
  /// Returns whether this call failed it.
  @override
  bool completeExceptionally(Object exception, [StackTrace? stackTrace]) {
    if (isCompleted || isBodyDone) {
      return false;
    }
    failBody(exception, stackTrace ?? StackTrace.current);
    return true;
  }
}
