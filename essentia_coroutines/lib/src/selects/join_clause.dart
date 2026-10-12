/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/selects/select_clause.dart';
import 'package:essentia_coroutines/src/selects/select_instance.dart';
import 'package:meta/meta.dart';

/// The `onJoin` clause of a job, which wins once the job is complete.
@internal
final class JoinClause implements SelectClause<void> {
  /// Creates the clause joining [_job].
  const JoinClause(this._job);

  /// The job waited for.
  final Job _job;

  /// Starts a lazily started job, like Kotlin's, and selects once it is
  /// complete.
  @override
  void register(SelectInstance select) {
    _job.start();
    if (_job.isCompleted) {
      select.trySelect(null);
      return;
    }
    select.disposeOnCompletion(
      _job.invokeOnCompletion((cause) => select.trySelect(null)),
    );
  }

  /// See [SelectClause.processResult].
  @override
  void processResult(Object? result) {}
}
