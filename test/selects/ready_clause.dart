/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:essentia/src/coroutines/disposable_action.dart';
import 'package:essentia/src/selects/select_instance.dart';

/// A clause that selects [value] at once and only then hands the select a
/// handle, recording in [disposals] when that handle is disposed.
final class ReadyClause implements SelectClause<int> {
  /// Creates the clause selecting [value].
  ReadyClause(this.value);

  /// The value the clause selects.
  final int value;

  /// How often the handle was disposed.
  var disposals = 0;

  /// See [SelectClause.register].
  @override
  void register(SelectInstance select) {
    select
      ..trySelect(value)
      ..disposeOnCompletion(DisposableAction(() => disposals++));
  }

  /// See [SelectClause.processResult].
  @override
  int processResult(Object? result) => result! as int;
}
