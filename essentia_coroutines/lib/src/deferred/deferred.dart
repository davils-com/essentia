/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
