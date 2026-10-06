/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/event/drop_reason.dart';
import 'package:essentia/src/event/event.dart';
import 'package:essentia/src/event/event_envelope.dart';
import 'package:essentia/src/event/mailbox.dart';
import 'package:meta/meta.dart';

/// The mailboxes and workers of one consumer group, one of each per
/// partition of its topic.
@internal
final class GroupMailboxes {
  /// Creates one mailbox of [capacity] and one worker running [_handle] for
  /// each of [partitions], reporting discarded envelopes to [_onDiscarded].
  GroupMailboxes(int partitions, int capacity, this._onDiscarded, this._handle)
    : _mailboxes = List<Mailbox<EventEnvelope<Event>>>.generate(
        partitions,
        (_) => Mailbox<EventEnvelope<Event>>(capacity),
      ) {
    workers = List<Future<void>>.unmodifiable(_mailboxes.map(_work));
  }

  /// One mailbox per partition.
  final List<Mailbox<EventEnvelope<Event>>> _mailboxes;

  /// Where a discarded envelope is reported.
  final void Function(EventEnvelope<Event> envelope, DropReason reason)
  _onDiscarded;

  /// What a worker runs for each envelope.
  final Future<void> Function(EventEnvelope<Event> envelope) _handle;

  /// How many workers are still running.
  var _running = 0;

  /// Whether the group was told to stop.
  var _cancelled = false;

  /// Whether buffered envelopes are discarded instead of handled.
  var _disposed = false;

  /// One task per partition, each completing once its mailbox is closed and
  /// empty.
  late final List<Future<void>> workers;

  /// Whether any worker is still being given work.
  bool get isActive => _running > 0 && !_cancelled;

  /// Hands [envelope] to the worker of [partition], waiting for room.
  ///
  /// An envelope offered to a mailbox that closed under it is reported as
  /// [DropReason.closed] rather than swallowed.
  Future<void> offer(int partition, EventEnvelope<Event> envelope) async {
    final bool accepted = await _mailboxes[partition].send(envelope);
    if (!accepted) {
      _onDiscarded(envelope, DropReason.closed);
    }
  }

  /// Stops taking envelopes; what is buffered is still handled.
  void close() {
    for (final Mailbox<EventEnvelope<Event>> mailbox in _mailboxes) {
      mailbox.close();
    }
  }

  /// Stops every worker after the envelope it is handling.
  void cancel() {
    _cancelled = true;
    for (final Mailbox<EventEnvelope<Event>> mailbox in _mailboxes) {
      mailbox.cancel();
    }
  }

  /// Completes once every worker has finished.
  Future<void> join() => Future.wait(workers);

  /// Discards everything buffered, reporting each envelope.
  void disposeBuffered() {
    _disposed = true;
    for (final Mailbox<EventEnvelope<Event>> mailbox in _mailboxes) {
      while (true) {
        final EventEnvelope<Event>? pending = mailbox.tryReceive();
        if (pending == null) {
          break;
        }
        _onDiscarded(pending, DropReason.disposed);
      }
    }
  }

  /// Handles what arrives in [mailbox] until it is closed and empty.
  Future<void> _work(Mailbox<EventEnvelope<Event>> mailbox) async {
    _running++;
    try {
      while (true) {
        final EventEnvelope<Event>? envelope = await mailbox.receive();
        if (envelope == null) {
          return;
        }
        if (_disposed) {
          _onDiscarded(envelope, DropReason.disposed);
          continue;
        }
        await _handle(envelope);
      }
    } finally {
      _running--;
    }
  }
}
