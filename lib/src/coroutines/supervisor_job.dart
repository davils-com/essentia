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
import 'package:essentia/src/coroutines/supervisor_job_impl.dart';

/// A job whose children fail on their own, Kotlin's `SupervisorJob`.
///
/// A failing child neither cancels the supervisor nor its siblings; a
/// child started with `launch` reports its failure to the
/// `CoroutineExceptionHandler` of its context instead. Cancelling the
/// supervisor still cancels every child.
///
/// ```dart
/// final scope = CoroutineScope(SupervisorJob());
/// scope.launch((it) => throw StateError('only this one fails'));
/// scope.launch((it) => keepsRunning());
/// ```
abstract interface class SupervisorJob implements CompletableJob {
  /// Creates an active supervisor, a child of [parent] if given.
  factory SupervisorJob([Job? parent]) = SupervisorJobImpl;
}
