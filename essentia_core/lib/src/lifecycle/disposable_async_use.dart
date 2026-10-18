/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_core/src/lifecycle/disposable_async.dart';

/// Kotlin's `use` on a [DisposableAsync]: a block that works with a
/// resource and leaves it disposed, waiting for the disposal, whichever way
/// it ends.
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
