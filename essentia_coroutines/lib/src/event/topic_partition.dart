/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/channels/channel_closed.dart';
import 'package:essentia_coroutines/src/channels/channel_result.dart';
import 'package:essentia_coroutines/src/coroutine/coroutine_scope_builders.dart';
import 'package:essentia_coroutines/src/coroutine/coroutine_start.dart';
import 'package:essentia_coroutines/src/event/drop_reason.dart';
import 'package:essentia_coroutines/src/event/envelope_lane.dart';
import 'package:essentia_coroutines/src/event/event.dart';
import 'package:essentia_coroutines/src/event/event_envelope.dart';
import 'package:essentia_coroutines/src/event/overflow_policy.dart';
import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/job/non_cancellable.dart';
import 'package:essentia_coroutines/src/scope/coroutine_scope.dart';
import 'package:meta/meta.dart';

/// One lane of a topic: a buffer of envelopes and the coroutine that
/// delivers them in order.
@internal
final class TopicPartition {
  /// Creates a lane buffering up to [capacity] envelopes, applying
  /// [_overflow] to a publisher that will not wait, reporting discarded
  /// envelopes to [_onDiscarded] and delivering through [_deliver] in a
  /// coroutine of [work].
  TopicPartition(
    int capacity,
    this._overflow,
    this._onDiscarded,
    this._deliver,
    CoroutineScope work,
  ) : _buffer = EnvelopeLane(capacity) {
    _pumping = work.launch((it) => _pump(), start: CoroutineStart.undispatched);
  }

  /// How many envelopes one publication that will not wait may evict
  /// before it gives up and is refused as an overflow itself.
  static const _evictionAttempts = 16;

  /// The buffered envelopes.
  final EnvelopeLane _buffer;

  /// What happens when the buffer is full and a publisher will not wait.
  final OverflowPolicy _overflow;

  /// Where a discarded envelope is reported.
  final void Function(EventEnvelope<Event> envelope, DropReason reason)
  _onDiscarded;

  /// Hands an envelope to everybody attached to the topic.
  final Future<void> Function(EventEnvelope<Event> envelope) _deliver;

  /// Whether buffered envelopes are discarded instead of delivered.
  var _disposed = false;

  /// The coroutine delivering this lane, started by the constructor.
  Job _pumping = NonCancellable.instance;

  /// Waits for the coroutine delivering this lane, which completes once the
  /// lane is closed and empty.
  Future<void> get pump => _pumping.join();

  /// How many envelopes are waiting in this lane right now.
  int get queueDepth => _buffer.length;

  /// Puts [envelope] into the lane, waiting for room if there is none.
  ///
  /// Returns `true` once it is in, `false` if the lane was closed, in which
  /// case the envelope has been reported as discarded.
  Future<bool> send(EventEnvelope<Event> envelope) async {
    final bool accepted = await _buffer.send(envelope);
    if (!accepted) {
      _onDiscarded(envelope, DropReason.closed);
    }
    return accepted;
  }

  /// Puts [envelope] into the lane without waiting, applying the overflow
  /// policy if there is no room.
  ///
  /// Returns `true` when it is in, `false` when it was refused, in which
  /// case it has been reported as discarded.
  bool offer(EventEnvelope<Event> envelope) {
    for (var attempt = 0; attempt < _evictionAttempts; attempt++) {
      final bool? outcome = _attempt(envelope);
      if (outcome != null) {
        return outcome;
      }
    }
    _onDiscarded(envelope, DropReason.overflow);
    return false;
  }

  /// Tries once to put [envelope] into the lane, evicting the oldest one
  /// when the policy allows it.
  ///
  /// Returns `true` when it is in, `false` when it was refused and
  /// reported, and `null` when an envelope was evicted to make room and the
  /// attempt should be repeated.
  bool? _attempt(EventEnvelope<Event> envelope) {
    switch (_buffer.trySend(envelope)) {
      case ChannelSuccess<void>():
        return true;
      case ChannelClosed<void>():
        _onDiscarded(envelope, DropReason.closed);
        return false;
      case ChannelFailure<void>():
        final EventEnvelope<Event>? evicted = _evictOldest();
        if (evicted == null) {
          _onDiscarded(envelope, DropReason.overflow);
          return false;
        }
        _onDiscarded(evicted, DropReason.overflow);
        return null;
    }
  }

  /// Stops taking envelopes; what is buffered is still delivered.
  void close() {
    _buffer.close();
  }

  /// Discards everything buffered, reporting each envelope, and everything
  /// that is still to come out of the lane.
  void disposeBuffered() {
    _disposed = true;
    while (true) {
      final EventEnvelope<Event>? pending = _buffer.tryReceive();
      if (pending == null) {
        return;
      }
      _onDiscarded(pending, DropReason.disposed);
    }
  }

  /// Delivers the lane in order until it is closed and empty.
  Future<void> _pump() async {
    while (true) {
      final EventEnvelope<Event>? envelope = await _buffer.receive();
      if (envelope == null) {
        return;
      }
      if (_disposed) {
        _onDiscarded(envelope, DropReason.disposed);
        continue;
      }
      await _deliver(envelope);
    }
  }

  /// Takes the envelope waiting longest out of the lane, if the policy says
  /// to make room that way.
  ///
  /// Returns the evicted envelope, or `null` when nothing is evicted.
  EventEnvelope<Event>? _evictOldest() {
    if (_overflow != OverflowPolicy.dropOldest) {
      return null;
    }
    return _buffer.tryReceive();
  }
}
