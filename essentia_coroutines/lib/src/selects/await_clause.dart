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

import 'package:essentia_coroutines/src/deferred/deferred.dart';
import 'package:essentia_coroutines/src/selects/select_clause.dart';
import 'package:essentia_coroutines/src/selects/select_instance.dart';
import 'package:meta/meta.dart';

/// The `onAwait` clause of a deferred, which wins once the deferred is
/// complete.
@internal
final class AwaitClause<T> implements SelectClause<T> {
  /// Creates the clause awaiting [_deferred].
  const AwaitClause(this._deferred);

  /// The deferred waited for.
  final Deferred<T> _deferred;

  /// Starts a lazily started deferred and selects once it is complete.
  @override
  void register(SelectInstance select) {
    _deferred.start();
    if (_deferred.isCompleted) {
      select.trySelect(null);
      return;
    }
    select.disposeOnCompletion(
      _deferred.invokeOnCompletion((cause) => select.trySelect(null)),
    );
  }

  /// The value of the deferred.
  ///
  /// Returns the value.
  ///
  /// Throws the failure of the deferred.
  @override
  T processResult(Object? result) => _deferred.getCompleted();
}
