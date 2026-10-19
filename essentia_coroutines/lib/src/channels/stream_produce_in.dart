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

import 'package:essentia_coroutines/src/channels/channel.dart';
import 'package:essentia_coroutines/src/channels/producer_coroutine.dart';
import 'package:essentia_coroutines/src/channels/producer_scope.dart';
import 'package:essentia_coroutines/src/channels/receive_channel.dart';
import 'package:essentia_coroutines/src/coroutine/coroutine_start.dart';
import 'package:essentia_coroutines/src/deferred/completable_deferred.dart';
import 'package:essentia_coroutines/src/scope/coroutine_scope.dart';

/// Turns a Dart `Stream` into a channel produced in a scope.
extension StreamProduceIn<T> on Stream<T> {
  /// Listens to the stream in a producer coroutine started in [scope] and hands
  /// out a channel of its events.
  ///
  /// The channel buffers the default `Channel.buffered` capacity; while it
  /// is full the subscription is paused. The channel is closed when the
  /// stream is done, and with the error when the stream fails - which, as
  /// any failure of a producer, also cancels [scope] unless its job is a
  /// supervisor. Cancelling the channel cancels the subscription.
  ///
  /// Returns the receiving side of the channel.
  ReceiveChannel<T> produceIn(CoroutineScope scope) => ProducerCoroutine<T>(
    scope.coroutineContext,
    Channel<T>(capacity: Channel.buffered),
  )..startProducer(CoroutineStart.atomic, _forward);

  /// Sends every event of the stream to [producer], pausing the
  /// subscription while a send waits.
  ///
  /// Returns a future that completes once the stream is done.
  ///
  /// Throws the error of the stream, and a cancellation once the producer
  /// is cancelled.
  Future<void> _forward(ProducerScope<T> producer) async {
    final done = CompletableDeferred<bool>();
    StreamSubscription<T>? subscription;
    subscription = listen(
      (value) {
        subscription?.pause();
        unawaited(
          producer
              .send(value)
              .then<void>(
                (sent) => subscription?.resume(),
                onError: done.completeExceptionally,
              ),
        );
      },
      onError: done.completeExceptionally,
      onDone: () => done.complete(true),
      cancelOnError: true,
    );
    try {
      await done;
    } finally {
      await subscription.cancel();
    }
  }
}
