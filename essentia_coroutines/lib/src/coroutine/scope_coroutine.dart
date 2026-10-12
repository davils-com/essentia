/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/coroutine/abstract_coroutine.dart';
import 'package:meta/meta.dart';

/// The coroutine of `coroutineScope` and `withContext`: its failure is
/// thrown to its caller, and it completes once its body and every child
/// did.
@internal
base class ScopeCoroutine<T> extends AbstractCoroutine<T> {
  /// Creates the coroutine as a child of the job of [parentContext].
  ScopeCoroutine(super.parentContext) : super(active: true);

  /// Completes once the coroutine reached its final state.
  final _result = Completer<T>();

  /// What the scope ends with: the value of its body, or its failure.
  Future<T> get result => _result.future;

  /// A failure is thrown to the caller, not passed to the parent.
  @override
  bool get isScopedCoroutine => true;

  /// Names the kind of coroutine.
  @override
  String get kind => 'ScopeCoroutine';

  /// Completes [result].
  @override
  void onCompletionInternal(AsyncError? error) {
    if (error != null) {
      _result.completeError(error.error, error.stackTrace);
      return;
    }
    _result.complete(outcome!.value);
  }
}
