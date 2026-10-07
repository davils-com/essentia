/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/coroutines/completable_job.dart';
import 'package:essentia/src/coroutines/job.dart';
import 'package:essentia/src/coroutines/job_support.dart';
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
