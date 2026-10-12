/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/job/disposable_action.dart';
import 'package:essentia_coroutines/src/scheduler/scheduled_task.dart';
import 'package:essentia_coroutines/src/scheduler/scheduler.dart';
import 'package:essentia_coroutines/src/selects/select_clause.dart';
import 'package:essentia_coroutines/src/selects/select_instance.dart';
import 'package:meta/meta.dart';

/// The clause of `onTimeout`, which wins once [_timeout] passed on the
/// scheduler of the current context.
@internal
final class TimeoutClause implements SelectClause<void> {
  /// Creates the clause waiting [_timeout].
  const TimeoutClause(this._timeout);

  /// How long the clause waits.
  final Duration _timeout;

  /// See [SelectClause.register].
  @override
  void register(SelectInstance select) {
    if (_timeout <= Duration.zero) {
      select.trySelect(null);
      return;
    }
    final ScheduledTask task = Scheduler.current.schedule(
      _timeout,
      () => select.trySelect(null),
    );
    select.disposeOnCompletion(DisposableAction(task.cancel));
  }

  /// See [SelectClause.processResult].
  @override
  void processResult(Object? result) {}
}
