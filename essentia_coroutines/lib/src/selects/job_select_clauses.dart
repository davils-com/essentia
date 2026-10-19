/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/selects/join_clause.dart';
import 'package:essentia_coroutines/src/selects/select_clause.dart';

/// The select clause of a `Job`.
extension JobSelectClauses on Job {
  /// The select clause that wins once the job is complete; a lazily started job
  /// is started.
  SelectClause<void> get onJoin => JoinClause(this);
}
