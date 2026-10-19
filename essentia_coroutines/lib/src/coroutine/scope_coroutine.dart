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
