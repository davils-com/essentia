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

import 'package:essentia_coroutines/src/channels/channel_closed.dart';
import 'package:essentia_coroutines/src/channels/channel_result.dart';
import 'package:essentia_coroutines/src/channels/closed_receive_channel_exception.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/selects/select_clause.dart';

/// The receiving side of a channel.
abstract interface class ReceiveChannel<E> {
  /// Whether the channel is closed and holds nothing more to receive.
  bool get isClosedForReceive;

  /// Whether a receive would wait right now: nothing is buffered, no sender
  /// waits and the channel is not closed for receive.
  bool get isEmpty;

  /// Receives the oldest element, waiting for one.
  ///
  /// The wait is cancellable. An element handed over after the receiver
  /// was cancelled goes to `onUndeliveredElement`.
  ///
  /// Returns the element.
  ///
  /// Throws a [ClosedReceiveChannelException] once the channel was closed
  /// without a cause and holds nothing more, the cause if it was closed
  /// with one, and a [CancellationException] if the receiver is cancelled
  /// while it waits.
  Future<E> receive();

  /// Receives the oldest element, waiting for one, or tells that the channel is
  /// closed.
  ///
  /// Returns a [ChannelSuccess] with the element, or a [ChannelClosed] with
  /// the cause once the channel is closed and holds nothing more.
  ///
  /// Throws a [CancellationException] if the receiver is cancelled while it
  /// waits.
  Future<ChannelResult<E>> receiveCatching();

  /// Receives the oldest element only if that needs no waiting.
  ///
  /// Returns a [ChannelSuccess] with the element, a [ChannelClosed] once the
  /// channel is closed and holds nothing more, and a [ChannelFailure] when
  /// it is empty.
  ChannelResult<E> tryReceive();

  /// Stops receiving and drops everything.
  ///
  /// The channel is closed with [cause], a [CancellationException] unless
  /// given; every buffered element and every element of a waiting sender
  /// goes to `onUndeliveredElement`, waiting senders end with the cause and
  /// waiting receivers with it too.
  void cancel([CancellationException? cause]);

  /// The select clause that receives an element.
  ///
  /// On a channel closed for receive it makes the select throw what
  /// [receive] would.
  SelectClause<E> get onReceive;

  /// The select clause that receives an element or tells that the channel is
  /// closed.
  SelectClause<ChannelResult<E>> get onReceiveCatching;
}
