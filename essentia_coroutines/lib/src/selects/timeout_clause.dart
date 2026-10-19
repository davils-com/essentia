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
