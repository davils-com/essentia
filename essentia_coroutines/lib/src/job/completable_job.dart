/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/job/job_impl.dart';

/// A job without a body that is completed by hand, Kotlin's
/// `CompletableJob`.
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

  /// Completes the job once its children did, Kotlin's `complete()`.
  ///
  /// Returns `true` when this call moved the job towards completion,
  /// `false` when it was completing, cancelling or complete already.
  bool complete();

  /// Fails the job with [exception], Kotlin's `completeExceptionally`.
  ///
  /// Returns `true` when this call failed the job, `false` when it was
  /// complete already.
  bool completeExceptionally(Object exception, [StackTrace? stackTrace]);
}
