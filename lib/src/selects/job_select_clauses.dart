/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/coroutines/job.dart';
import 'package:essentia/src/selects/join_clause.dart';
import 'package:essentia/src/selects/select_clause.dart';

/// Kotlin's select clause of `Job`.
extension JobSelectClauses on Job {
  /// The select clause that wins once the job is complete, Kotlin's
  /// `Job.onJoin`; a lazily started job is started.
  SelectClause<void> get onJoin => JoinClause(this);
}
