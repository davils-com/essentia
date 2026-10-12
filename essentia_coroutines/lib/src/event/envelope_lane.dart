/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/channels/buffered_channel.dart';
import 'package:essentia_coroutines/src/channels/channel_result.dart';
import 'package:essentia_coroutines/src/continuation/suspension.dart';
import 'package:essentia_coroutines/src/event/event.dart';
import 'package:essentia_coroutines/src/event/event_envelope.dart';
import 'package:meta/meta.dart';

/// A bounded channel of envelopes between the tasks of a topic: a lane
/// of a partition, the mailbox of a subscriber or of a group worker.
///
/// It is an Essentia `Channel` with the answers a topic needs: a sender
/// that finds the lane closed is told so instead of failing, and a
/// receiver that finds it closed and empty gets `null`. A lane of capacity
/// zero is a rendezvous. [close] stops new sends and still hands out what
/// is buffered or waiting; [cancel] drops all of it.
@internal
final class EnvelopeLane {
  /// Creates a lane holding up to [capacity] envelopes.
  EnvelopeLane(int capacity)
    : _channel = BufferedChannel<EventEnvelope<Event>>(capacity: capacity);

  /// The channel behind the lane.
  final BufferedChannel<EventEnvelope<Event>> _channel;

  /// How many envelopes wait to be received, buffered or held by a waiting
  /// sender.
  int get length => _channel.size;

  /// Sends [envelope], waiting for room if there is none.
  ///
  /// The wait is cancellable: a sender whose own job is cancelled ends
  /// with its `CancellationException`.
  ///
  /// Returns `true` once the lane took the envelope, `false` if it was
  /// closed before or cancelled while waiting.
  Future<bool> send(EventEnvelope<Event> envelope) async {
    if (_channel.isClosedForSend) {
      return false;
    }
    try {
      await _channel.send(envelope);
      return true;
    } on Object catch (error) {
      if (isCurrentCancellation(error)) {
        rethrow;
      }
      return false;
    }
  }

  /// Sends [envelope] without waiting.
  ///
  /// Returns the result: a success when the lane took it, a closed result
  /// when the lane is closed, and a failure when it is full.
  ChannelResult<void> trySend(EventEnvelope<Event> envelope) =>
      _channel.trySend(envelope);

  /// Receives the next envelope, waiting for one if the lane is empty.
  ///
  /// Returns the envelope, or `null` once the lane is closed and empty or
  /// cancelled.
  Future<EventEnvelope<Event>?> receive() async =>
      (await _channel.receiveCatching()).getOrNull();

  /// Receives the next envelope without waiting.
  ///
  /// Returns it, or `null` when none is there.
  EventEnvelope<Event>? tryReceive() => _channel.tryReceive().getOrNull();

  /// Stops new sends; what is buffered or waiting is still received.
  void close() => _channel.close();

  /// Drops everything buffered or waiting and releases every sender and
  /// receiver.
  void cancel() => _channel.cancel();
}
