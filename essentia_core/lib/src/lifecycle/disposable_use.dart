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

import 'package:essentia_core/src/lifecycle/disposable.dart';

/// Runs a block that works with a [Disposable] and leaves it disposed,
/// whichever way the block ends.
///
/// ```dart
/// final int size = openArchive(path).use((it) => it.entries.length);
/// ```
extension DisposableUse<T extends Disposable> on T {
  /// Runs [block] with this object and disposes it afterwards.
  ///
  /// If [block] fails, its failure is thrown on and a failure of the
  /// disposal is dropped, so the first problem is the one reported; if
  /// [block] succeeds, a failure of the disposal is thrown.
  ///
  /// Returns what [block] returns.
  ///
  /// Throws an [ArgumentError] if [block] returns a [Future], after
  /// disposing: the object would be gone before the future is done, which
  /// is what [useAsync] is for.
  R use<R>(R Function(T it) block) {
    final R result;
    try {
      result = block(this);
    } on Object {
      _disposeQuietly(this);
      rethrow;
    }
    dispose();
    if (result is Future<Object?>) {
      result.ignore();
      throw ArgumentError.value(
        result,
        'block',
        'returns a Future, which use cannot wait for; call useAsync',
      );
    }
    return result;
  }

  /// Runs [block] with this object and disposes it once what [block]
  /// returns is complete.
  ///
  /// Failures are treated as by [use].
  ///
  /// Returns what [block] returns.
  Future<R> useAsync<R>(FutureOr<R> Function(T it) block) async {
    final R result;
    try {
      result = await block(this);
    } on Object {
      _disposeQuietly(this);
      rethrow;
    }
    dispose();
    return result;
  }
}

/// Disposes [resource], dropping what its disposal throws.
void _disposeQuietly(Disposable resource) {
  try {
    resource.dispose();
  } on Object {
    return;
  }
}
