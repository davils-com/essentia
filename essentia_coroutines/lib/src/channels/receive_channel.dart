/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
