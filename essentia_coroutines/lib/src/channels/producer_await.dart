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

import 'package:essentia_coroutines/src/channels/producer_scope.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_zone.dart';
import 'package:essentia_coroutines/src/continuation/suspension.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/job/job.dart';

/// Waiting for the end of the channel of a `ProducerScope`.
extension ProducerAwait on ProducerScope<Object?> {
  /// Waits until the channel is closed or cancelled, then runs [block].
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
