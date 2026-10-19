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
import 'package:essentia_coroutines/src/channels/closed_send_channel_exception.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/selects/select_clause.dart';

/// The sending side of a channel.
abstract interface class SendChannel<E> {
  /// Whether the channel refuses new elements because it was closed or
  /// cancelled.
  bool get isClosedForSend;

  /// Sends [element], waiting while the buffer is full.
  ///
  /// The element is handed to a waiting receiver, buffered, or - when the
  /// buffer is full - dropped or waited with, as the overflow policy of the
  /// channel says. The wait is cancellable, and cancellation is checked only
  /// when the send has to wait; a sender cancelled while waiting hands its
  /// element to `onUndeliveredElement`. A send to a closed channel hands its
  /// element to `onUndeliveredElement` as well.
  ///
  /// Returns a future that completes once the channel took the element.
  ///
  /// Throws a [ClosedSendChannelException] if the channel was closed
  /// without a cause, the cause if it was closed with one, and a
  /// [CancellationException] if the sender is cancelled while it waits.
  Future<void> send(E element);

  /// Sends [element] only if that needs no waiting.
  ///
  /// Returns a [ChannelSuccess] when the channel took or - by its overflow
  /// policy - dropped the element, a [ChannelClosed] carrying the reason
  /// [send] would throw when the channel is closed, and a [ChannelFailure]
  /// when it is full.
  ChannelResult<void> trySend(E element);

  /// Closes the channel for new elements.
  ///
  /// What is buffered, and what senders already waiting hold, is still
  /// received; receivers that find nothing more afterwards end with [cause]
  /// or a `ClosedReceiveChannelException`. The handler of [invokeOnClose]
  /// runs.
  ///
  /// Returns `true` when this call closed the channel, `false` when it was
  /// closed already.
  bool close([Object? cause]);

  /// Registers [handler] to run once the channel is closed or cancelled, with
  /// the cause.
  ///
  /// It runs at once when the channel is closed already.
  ///
  /// Throws a [StateError] if a handler was registered already.
  void invokeOnClose(void Function(Object? cause) handler);

  /// The select clause that sends [element].
  ///
  /// It wins once the channel takes the element and hands the block this
  /// channel; on a closed channel it makes the select throw what [send]
  /// would.
  SelectClause<SendChannel<E>> onSend(E element);
}
