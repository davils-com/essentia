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

  /// Starts a lazily started job and selects once it is complete.
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
