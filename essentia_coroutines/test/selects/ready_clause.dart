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

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_coroutines/src/job/disposable_action.dart';
import 'package:essentia_coroutines/src/selects/select_instance.dart';

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
