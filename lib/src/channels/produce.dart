/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/channels/buffer_overflow.dart';
import 'package:essentia/src/channels/channel.dart';
import 'package:essentia/src/channels/producer_coroutine.dart';
import 'package:essentia/src/channels/producer_scope.dart';
import 'package:essentia/src/channels/receive_channel.dart';
import 'package:essentia/src/coroutines/coroutine_context.dart';
import 'package:essentia/src/coroutines/coroutine_scope.dart';
import 'package:essentia/src/coroutines/coroutine_start.dart';

/// Kotlin's `produce` coroutine builder.
extension Produce on CoroutineScope {
  /// Starts [block] as a child of the scope's job, sending to a new
  /// channel, and hands out the receiving side, Kotlin's `produce`.
  ///
  /// The channel buffers [capacity] elements with [onBufferOverflow], as
  /// `Channel()` does, and [context] is laid over the scope's context. The
  /// channel is closed once the coroutine completes - with its failure as
  /// the cause when it fails, so the consumer receives that failure after
  /// the last element. Cancelling the channel cancels the coroutine. A
  /// failure cancels the scope like one of `launch`, unless its job is a
  /// supervisor.
  ///
  /// ```dart
  /// ReceiveChannel<int> numbersFrom(CoroutineScope scope, int start) =>
  ///     scope.produce((it) async {
  ///       for (var x = start; ; x++) {
  ///         await it.send(x);
  ///       }
  ///     });
  /// ```
  ///
  /// Returns the receiving side of the channel.
  ReceiveChannel<E> produce<E>(
    FutureOr<void> Function(ProducerScope<E> it) block, {
    int capacity = Channel.rendezvous,
    BufferOverflow onBufferOverflow = BufferOverflow.suspend,
    CoroutineContext context = CoroutineContext.empty,
  }) => ProducerCoroutine<E>(
    coroutineContext + context,
    Channel<E>(capacity: capacity, onBufferOverflow: onBufferOverflow),
  )..startProducer(CoroutineStart.defaultStart, block);
}
