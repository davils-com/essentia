/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/channels/producer_scope.dart';
import 'package:essentia/src/coroutines/cancellation_exception.dart';
import 'package:essentia/src/coroutines/coroutine_context_zone.dart';
import 'package:essentia/src/coroutines/job.dart';
import 'package:essentia/src/coroutines/suspension.dart';

/// Kotlin's `awaitClose` on a `ProducerScope`.
extension ProducerAwait on ProducerScope<Object?> {
  /// Waits until the channel is closed or cancelled, then runs [block],
  /// Kotlin's `awaitClose`.
  ///
  /// It keeps a producer that hands a callback API over to the channel
  /// alive, and [block] unregisters the callback:
  ///
  /// ```dart
  /// final ReceiveChannel<Tick> ticks = scope.produce((it) async {
  ///   final Subscription subscription = clock.onTick(it.trySend);
  ///   await it.awaitClose(subscription.cancel);
  /// });
  /// ```
  ///
  /// [block] runs as well when the producer is cancelled while it waits.
  /// The wait takes the `invokeOnClose` handler of the channel.
  ///
  /// Returns a future that completes once the channel is closed.
  ///
  /// Throws a [StateError] if it is not called from the producer's own
  /// coroutine or if the channel has a close handler already, and a
  /// [CancellationException] if the producer is cancelled while it waits.
  Future<void> awaitClose([void Function()? block]) async {
    final Job? producer = coroutineContext.get(Job.key);
    if (!identical(currentCoroutineContext().get(Job.key), producer)) {
      throw StateError('awaitClose() can only be called from the producer');
    }
    try {
      await suspendCancellableCoroutine<void>(
        (it) => invokeOnClose((cause) => it.resume(null)),
      );
    } finally {
      block?.call();
    }
  }
}
