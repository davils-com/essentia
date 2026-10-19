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

import 'package:essentia_core/src/lifecycle/disposable_async.dart';

/// Runs a block that works with a [DisposableAsync] and leaves it disposed,
/// waiting for the disposal, whichever way the block ends.
///
/// ```dart
/// await openQueue().useAsync((it) => it.send(message));
/// ```
extension DisposableAsyncUse<T extends DisposableAsync> on T {
  /// Runs [block] with this object and disposes it once what [block]
  /// returns is complete, completing once the disposal is.
  ///
  /// If [block] fails, its failure is thrown on and a failure of the
  /// disposal is dropped, so the first problem is the one reported; if
  /// [block] succeeds, a failure of the disposal is thrown.
  ///
  /// A type that is both a `Disposable` and a [DisposableAsync] has two
  /// `useAsync`; name the one meant, `DisposableAsyncUse(it).useAsync`.
  ///
  /// Returns what [block] returns.
  Future<R> useAsync<R>(FutureOr<R> Function(T it) block) async {
    final R result;
    try {
      result = await block(this);
    } on Object {
      await _disposeQuietly(this);
      rethrow;
    }
    await dispose();
    return result;
  }
}

/// Disposes [resource], dropping what its disposal throws.
Future<void> _disposeQuietly(DisposableAsync resource) async {
  try {
    await resource.dispose();
  } on Object {
    return;
  }
}
