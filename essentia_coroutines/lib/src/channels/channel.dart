/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/channels/buffer_overflow.dart';
import 'package:essentia_coroutines/src/channels/buffered_channel.dart';
import 'package:essentia_coroutines/src/channels/receive_channel.dart';
import 'package:essentia_coroutines/src/channels/send_channel.dart';

/// A queue between pieces of asynchronous work: senders wait while it is
/// full and receivers while it is empty, Kotlin's `Channel`.
///
/// Every element sent is received exactly once, by one receiver, in the
/// order it was sent; several receivers share the elements (fan-out), and
/// several senders feed one channel (fan-in). Waiting senders and
/// receivers are served oldest first, and every wait is cancellable.
///
/// [close] stops new sends while the receivers still get everything sent
/// before; `cancel` drops it all. An element that is never received - it
/// was buffered when the channel was cancelled, its sender was cancelled,
/// or its receiver was cancelled just after it was handed over - goes to
/// `onUndeliveredElement`, so a resource it holds can be released.
///
/// Elements may be `null`: a `Channel<int?>` works, because closure is a
/// state of the channel and not a value.
///
/// ```dart
/// final channel = Channel<int>();
/// scope.launch((it) async {
///   for (var x = 1; x <= 5; x++) {
///     await channel.send(x * x);
///   }
///   channel.close();
/// });
/// await channel.consumeEach(print);
/// ```
abstract interface class Channel<E>
    implements SendChannel<E>, ReceiveChannel<E> {
  /// Creates a channel buffering up to [capacity] elements, applying
  /// [onBufferOverflow] once the buffer is full and handing every element
  /// that is never received to [onUndeliveredElement], Kotlin's
  /// `Channel(capacity, onBufferOverflow, onUndeliveredElement)`.
  ///
  /// [capacity] is a number of elements or one of [rendezvous], [buffered],
  /// [conflated] and [unlimited]. Like Kotlin's, a [rendezvous] or
  /// [buffered] channel with an overflow policy other than
  /// [BufferOverflow.suspend] buffers one element, and an [unlimited]
  /// channel never overflows.
  ///
  /// Throws an [ArgumentError] if [capacity] is negative and none of these
  /// constants, or if a [conflated] channel is given an overflow policy
  /// other than [BufferOverflow.suspend].
  factory Channel({
    int capacity = rendezvous,
    BufferOverflow onBufferOverflow = BufferOverflow.suspend,
    void Function(E element)? onUndeliveredElement,
  }) => BufferedChannel<E>(
    capacity: capacity,
    onBufferOverflow: onBufferOverflow,
    onUndeliveredElement: onUndeliveredElement,
  );

  /// No buffer: a send completes once a receiver took the element, Kotlin's
  /// `Channel.RENDEZVOUS`.
  static const rendezvous = 0;

  /// A buffer without a bound, Kotlin's `Channel.UNLIMITED`; a send never
  /// waits. The value is `0x7fffffff` on every platform.
  static const unlimited = 0x7fffffff;

  /// A buffer of one element that the newest element replaces, Kotlin's
  /// `Channel.CONFLATED`: capacity one and [BufferOverflow.dropOldest].
  static const conflated = -1;

  /// The default buffer of [defaultCapacity] elements, Kotlin's
  /// `Channel.BUFFERED`.
  static const buffered = -2;

  /// How many elements a [buffered] channel holds, Kotlin's default of 64.
  static const defaultCapacity = 64;
}
