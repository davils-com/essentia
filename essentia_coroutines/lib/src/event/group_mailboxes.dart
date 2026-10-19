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

import 'package:essentia_coroutines/src/coroutine/coroutine_scope_builders.dart';
import 'package:essentia_coroutines/src/coroutine/coroutine_start.dart';
import 'package:essentia_coroutines/src/event/drop_reason.dart';
import 'package:essentia_coroutines/src/event/envelope_lane.dart';
import 'package:essentia_coroutines/src/event/event.dart';
import 'package:essentia_coroutines/src/event/event_envelope.dart';
import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/job/join_all.dart';
import 'package:essentia_coroutines/src/scope/coroutine_scope.dart';
import 'package:meta/meta.dart';

/// The mailboxes and workers of one consumer group, one of each per
/// partition of its topic.
@internal
final class GroupMailboxes {
  /// Creates one mailbox of [capacity] and one worker running [_handle] for
  /// each of [partitions], reporting discarded envelopes to [_onDiscarded];
  /// the workers are coroutines of [work].
  GroupMailboxes(
    int partitions,
    int capacity,
    this._onDiscarded,
    this._handle,
    CoroutineScope work,
  ) : _mailboxes = List<EnvelopeLane>.generate(
        partitions,
        (_) => EnvelopeLane(capacity),
      ) {
    _workers.addAll(
      _mailboxes.map(
        (mailbox) => work.launch(
          (it) => _work(mailbox),
          start: CoroutineStart.undispatched,
        ),
      ),
    );
  }

  /// One mailbox per partition.
  final List<EnvelopeLane> _mailboxes;

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

  /// One worker coroutine per partition, each completing once its mailbox
  /// is closed and empty; filled by the constructor and never changed
  /// afterwards.
  final _workers = <Job>[];

  /// How many workers the group holds, one per partition.
  int get workerCount => _workers.length;

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
    for (final EnvelopeLane mailbox in _mailboxes) {
      mailbox.close();
    }
  }

  /// Stops every worker after the envelope it is handling.
  void cancel() {
    _cancelled = true;
    for (final EnvelopeLane mailbox in _mailboxes) {
      mailbox.cancel();
    }
  }

  /// Completes once every worker has finished.
  Future<void> join() => _workers.joinAll();

  /// Discards everything buffered, reporting each envelope.
  void disposeBuffered() {
    _disposed = true;
    for (final EnvelopeLane mailbox in _mailboxes) {
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
  Future<void> _work(EnvelopeLane mailbox) async {
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
