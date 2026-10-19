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

import 'dart:collection';

import 'package:essentia_coroutines/essentia_coroutines.dart';

/// A pure reference of a channel: a queue, the waiting senders and receivers,
/// and the fate of every element, following the channel contract.
final class ChannelModel {
  /// Creates the model of a channel buffering [capacity] elements with
  /// [overflow] beyond.
  ChannelModel(this.capacity, this.overflow);

  /// How many elements the buffer holds.
  final int capacity;

  /// What a send to a full buffer does.
  final BufferOverflow overflow;

  /// The buffered elements, oldest first.
  final buffer = Queue<int>();

  /// The waiting senders with their elements, oldest first.
  final senders = <({int sender, int element})>[];

  /// The waiting receivers, oldest first.
  final receivers = <int>[];

  /// Whether the channel was closed or cancelled.
  var closed = false;

  /// Every element handed to a receiver, in order, with the receiver.
  final deliveries = <({int receiver, int element})>[];

  /// Every element reported as undelivered, in order.
  final undelivered = <int>[];

  /// Every element `trySend` dropped without a report, as
  /// [BufferOverflow.dropLatest] does.
  final dropped = <int>[];

  /// The receivers that learned the channel is closed.
  final closedReceivers = <int>{};

  /// What became of each sender: `sent` or `failed`.
  final senderOutcomes = <int, String>{};

  /// Sends [element] for [sender], waiting if it has to.
  void send(int sender, int element) {
    if (closed) {
      undelivered.add(element);
      senderOutcomes[sender] = 'failed';
      return;
    }
    if (_offer(element, sending: true)) {
      senderOutcomes[sender] = 'sent';
      return;
    }
    senders.add((sender: sender, element: element));
  }

  /// Sends [element] without waiting.
  ///
  /// Returns what `trySend` should return.
  ChannelResult<void> trySend(int element) {
    if (closed) {
      return ChannelClosed<void>(ClosedSendChannelException());
    }
    if (_offer(element, sending: false)) {
      return const ChannelSuccess<void>(null);
    }
    return const ChannelFailure<void>();
  }

  /// Receives for [receiver], waiting if it has to.
  void receive(int receiver) {
    final int? element = _take();
    if (element != null) {
      deliveries.add((receiver: receiver, element: element));
      return;
    }
    if (isClosedForReceive) {
      closedReceivers.add(receiver);
      return;
    }
    receivers.add(receiver);
  }

  /// Receives without waiting.
  ///
  /// Returns the element, or `null` when `tryReceive` should fail.
  int? tryReceive() => _take();

  /// Closes the channel.
  void close() {
    if (closed) {
      return;
    }
    closed = true;
    if (isClosedForReceive) {
      closedReceivers.addAll(receivers);
      receivers.clear();
    }
  }

  /// Cancels the channel.
  void cancel() {
    closed = true;
    undelivered.addAll(buffer);
    buffer.clear();
    for (final (:sender, :element) in senders) {
      undelivered.add(element);
      senderOutcomes[sender] = 'failed';
    }
    senders.clear();
    closedReceivers.addAll(receivers);
    receivers.clear();
  }

  /// Cancels the waiting [sender].
  void cancelSender(int sender) {
    final int index = senders.indexWhere((waiter) => waiter.sender == sender);
    undelivered.add(senders.removeAt(index).element);
    senderOutcomes[sender] = 'failed';
  }

  /// Cancels the waiting [receiver].
  void cancelReceiver(int receiver) => receivers.remove(receiver);

  /// Whether the channel is closed and holds nothing more.
  bool get isClosedForReceive => closed && buffer.isEmpty && senders.isEmpty;

  /// Hands [element] over, buffers it or applies the overflow policy.
  ///
  /// Returns `false` when the sender has to wait.
  bool _offer(int element, {required bool sending}) {
    if (receivers.isNotEmpty) {
      deliveries.add((receiver: receivers.removeAt(0), element: element));
      return true;
    }
    if (buffer.length < capacity) {
      buffer.add(element);
      return true;
    }
    switch (overflow) {
      case BufferOverflow.suspend:
        return false;
      case BufferOverflow.dropOldest:
        undelivered.add(buffer.removeFirst());
        buffer.add(element);
        return true;
      case BufferOverflow.dropLatest:
        if (!sending) {
          dropped.add(element);
          return true;
        }
        undelivered.add(element);
        return true;
    }
  }

  /// Takes the next element: the oldest buffered one, admitting a waiting
  /// sender, or the one of the oldest waiting sender.
  ///
  /// Returns the element, or `null` when there is none.
  int? _take() {
    if (buffer.isNotEmpty) {
      final int element = buffer.removeFirst();
      if (senders.isNotEmpty && buffer.length < capacity) {
        final (:int sender, element: int admitted) = senders.removeAt(0);
        buffer.add(admitted);
        senderOutcomes[sender] = 'sent';
      }
      return element;
    }
    if (senders.isNotEmpty) {
      final (:int sender, :int element) = senders.removeAt(0);
      senderOutcomes[sender] = 'sent';
      return element;
    }
    return null;
  }
}
