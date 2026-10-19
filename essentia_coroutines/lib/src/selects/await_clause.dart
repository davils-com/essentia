/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
