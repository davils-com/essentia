/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/coroutines/deferred.dart';
import 'package:essentia/src/selects/await_clause.dart';
import 'package:essentia/src/selects/select_clause.dart';

/// Kotlin's select clause of `Deferred`.
extension DeferredSelectClauses<T> on Deferred<T> {
  /// The select clause that wins with the value once the deferred is
  /// complete, Kotlin's `Deferred.onAwait`; a failed deferred makes the
  /// select throw its failure, and a lazily started one is started.
  SelectClause<T> get onAwait => AwaitClause<T>(this);
}
