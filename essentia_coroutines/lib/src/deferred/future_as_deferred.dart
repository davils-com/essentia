/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/deferred/completable_deferred.dart';
import 'package:essentia_coroutines/src/deferred/deferred.dart';

/// Turns a plain `Future` into a `Deferred`.
extension FutureAsDeferred<T> on Future<T> {
  /// A deferred that completes with this future.
  ///
  /// Awaiting a plain future is not cancellable; awaiting the deferred is,
  /// although the work behind the future goes on.
  ///
  /// Returns the deferred.
  Deferred<T> asDeferred() {
    final deferred = CompletableDeferred<T>();
    unawaited(
      then<void>(deferred.complete, onError: deferred.completeExceptionally),
    );
    return deferred;
  }
}
