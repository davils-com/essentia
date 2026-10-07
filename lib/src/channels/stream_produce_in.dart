/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/channels/channel.dart';
import 'package:essentia/src/channels/producer_coroutine.dart';
import 'package:essentia/src/channels/producer_scope.dart';
import 'package:essentia/src/channels/receive_channel.dart';
import 'package:essentia/src/coroutines/completable_deferred.dart';
import 'package:essentia/src/coroutines/coroutine_scope.dart';
import 'package:essentia/src/coroutines/coroutine_start.dart';

/// Kotlin's `Flow.produceIn` on a Dart `Stream`.
extension StreamProduceIn<T> on Stream<T> {
  /// Listens to the stream in a producer coroutine started in [scope] and
  /// hands out a channel of its events, Kotlin's `Flow.produceIn(scope)`.
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
