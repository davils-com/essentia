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

import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/job/job.dart';

/// A job with a result.
///
/// A deferred is a `Future`, so `await deferred` waits for its result. Awaiting
/// is cancellable: the waiting code ends with a [CancellationException] once
/// its own job is cancelled, and a lazily started deferred is started by
/// awaiting it.
///
/// ```dart
/// final Deferred<User> user = scope.async((it) => loadUser(id));
/// final Deferred<List<Order>> orders = scope.async((it) => loadOrders(id));
/// render(await user, await orders);
/// ```
abstract interface class Deferred<T> implements Job, Future<T> {
  /// The result of a completed deferred.
  ///
  /// Returns the value.
  ///
  /// Throws the failure of the deferred if it failed, and a [StateError] if
  /// it is not complete yet.
  T getCompleted();

  /// The failure of a completed deferred.
  ///
  /// Returns the failure or cancellation, or `null` after a normal
  /// completion.
  ///
  /// Throws a [StateError] if the deferred is not complete yet.
  Object? getCompletionExceptionOrNull();
}
