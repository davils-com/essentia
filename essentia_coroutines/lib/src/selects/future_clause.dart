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
import 'package:essentia_coroutines/src/selects/select_instance.dart';
import 'package:meta/meta.dart';

/// The clause of `onFuture`, which wins once a plain future completes.
///
/// A future cannot be called off, so a select that ends otherwise only
/// stops listening to it.
@internal
final class FutureClause<T> implements SelectClause<T> {
  /// Creates the clause waiting for [_future].
  const FutureClause(this._future);

  /// The future waited for.
  final Future<T> _future;

  /// Selects with the value or the failure of the future, in a later
  /// microtask even when it is complete already.
  @override
  void register(SelectInstance select) {
    unawaited(
      _future.then<void>(
        (value) => select.trySelect((value: value)),
        onError: (Object error, StackTrace stackTrace) =>
            select.trySelect(AsyncError(error, stackTrace)),
      ),
    );
  }

  /// The value of the future.
  ///
  /// Returns the value.
  ///
  /// Throws the failure of the future.
  @override
  T processResult(Object? result) {
    if (result is AsyncError) {
      Error.throwWithStackTrace(result.error, result.stackTrace);
    }
    return (result! as ({T value})).value;
  }
}
