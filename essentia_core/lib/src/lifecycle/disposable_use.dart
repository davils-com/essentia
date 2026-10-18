/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_core/src/lifecycle/disposable.dart';

/// Kotlin's `use` on a [Disposable]: a block that works with a resource and
/// leaves it disposed, whichever way it ends.
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
