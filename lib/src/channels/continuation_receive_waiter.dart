/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/channels/buffered_channel.dart';
import 'package:essentia/src/channels/channel_result.dart';
import 'package:essentia/src/channels/receive_waiter.dart';
import 'package:essentia/src/coroutines/cancellable_continuation.dart';
import 'package:meta/meta.dart';

/// The waiter of a plain receive, resumed through its continuation.
@internal
final class ContinuationReceiveWaiter<E> extends ReceiveWaiter<E> {
  /// Creates the waiter of a receive from [_channel] that waits in
  /// [_continuation].
  ContinuationReceiveWaiter(this._channel, this._continuation);

  /// The channel the receiver waits on.
  final BufferedChannel<E> _channel;

  /// The continuation of the waiting receive.
  final CancellableContinuation<ChannelResult<E>> _continuation;

  /// Hands [result] over; an element the receiver is cancelled before it
  /// takes goes to the channel's `onUndeliveredElement`.
  @override
  bool resume(ChannelResult<E> result) {
    if (!_continuation.isActive) {
      return false;
    }
    _continuation.resume(
      result,
      onCancellation: (cause, value) => _channel.undeliverResult(value),
    );
    return true;
  }
}
