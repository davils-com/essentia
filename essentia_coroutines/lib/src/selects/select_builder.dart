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

import 'dart:async';

import 'package:essentia_coroutines/src/selects/select_clause.dart';

/// What the block of `select` registers its clauses with.
///
/// Dart has no receiver-scoped clause syntax, so a clause is registered by
/// a call on the builder: [invoke] with a clause such as
/// `channel.onReceive`, or one of the shortcuts of
/// `SelectBuilderClauses`, such as `it.onReceive(channel, block)`.
abstract interface class SelectBuilder<R> {
  /// Registers [clause]; once it wins, [block] runs with what it selected and
  /// its result is the result of the select.
  void invoke<Q>(SelectClause<Q> clause, FutureOr<R> Function(Q value) block);

  /// Registers a clause that wins once [timeout] passed.
  ///
  /// The time is measured on the scheduler of the current context, so it
  /// is virtual under `runTest`; a zero or negative [timeout] is ready at
  /// once.
  void onTimeout(Duration timeout, FutureOr<R> Function() block);
}
