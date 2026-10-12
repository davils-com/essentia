/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/job/job_impl.dart';
import 'package:essentia_coroutines/src/job/supervisor_job.dart';
import 'package:meta/meta.dart';

/// The job behind `SupervisorJob()`: it never takes over a failure of a
/// child.
@internal
final class SupervisorJobImpl extends JobImpl implements SupervisorJob {
  /// Creates an active supervisor, a child of [parent] if given.
  SupervisorJobImpl([super.parent]);

  /// Leaves the failure of a child to the child.
  ///
  /// Returns `false`.
  @override
  bool childCancelled(Object cause, StackTrace stackTrace) => false;

  /// Names the supervisor.
  @override
  String get debugName => 'SupervisorJob';
}
