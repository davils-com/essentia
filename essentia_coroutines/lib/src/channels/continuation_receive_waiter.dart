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

import 'package:essentia_coroutines/src/channels/buffered_channel.dart';
import 'package:essentia_coroutines/src/channels/channel_result.dart';
import 'package:essentia_coroutines/src/channels/receive_waiter.dart';
import 'package:essentia_coroutines/src/continuation/cancellable_continuation.dart';
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
