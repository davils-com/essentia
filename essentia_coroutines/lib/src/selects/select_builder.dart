/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/selects/select_clause.dart';

/// What the block of `select` registers its clauses with, Kotlin's
/// `SelectBuilder`.
///
/// Dart has no receiver-scoped clause syntax, so a clause is registered by
/// a call on the builder: [invoke] with a clause such as
/// `channel.onReceive`, or one of the shortcuts of
/// `SelectBuilderClauses`, such as `it.onReceive(channel, block)`.
abstract interface class SelectBuilder<R> {
  /// Registers [clause]; once it wins, [block] runs with what it selected
  /// and its result is the result of the select, Kotlin's
  /// `SelectClause.invoke(block)`.
  void invoke<Q>(SelectClause<Q> clause, FutureOr<R> Function(Q value) block);

  /// Registers a clause that wins once [timeout] passed, Kotlin's
  /// `onTimeout`.
  ///
  /// The time is measured on the scheduler of the current context, so it
  /// is virtual under `runTest`; a zero or negative [timeout] is ready at
  /// once.
  void onTimeout(Duration timeout, FutureOr<R> Function() block);
}
