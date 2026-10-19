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
