/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/coroutines/completable_job.dart';
import 'package:essentia/src/coroutines/coroutine_scope.dart';
import 'package:essentia/src/coroutines/coroutine_scope_builders.dart';
import 'package:essentia/src/coroutines/coroutine_start.dart';
import 'package:essentia/src/coroutines/job.dart';
import 'package:essentia/src/event/envelope_lane.dart';
import 'package:essentia/src/event/event.dart';
import 'package:essentia/src/event/event_envelope.dart';
import 'package:meta/meta.dart';

/// One broadcast attachment to a topic: its mailbox and the task working
/// through it.
@internal
final class Subscriber {
  /// Creates the subscriber [name] holding up to [capacity] envelopes, which
  /// hands each to [_consume], stops after the first one consumed when
  /// [_once] is set, and calls [_detach] when it ends.
  Subscriber(
    this.name,
    int capacity,
    this._consume,
    this._detach, {
    required this._once,
  }) : _mailbox = EnvelopeLane(capacity);

  /// What this subscriber is reported under.
  final String name;

  /// The envelopes handed to this subscriber and not yet taken.
  final EnvelopeLane _mailbox;

  /// Runs the consumer for one envelope, answering whether the envelope
  /// matched what the subscriber listens for.
  final Future<bool> Function(EventEnvelope<Event> envelope) _consume;

  /// Removes this subscriber from its topic.
  final void Function(Subscriber subscriber) _detach;

  /// Whether the subscriber ends after the first matching envelope.
  final bool _once;

  /// Whether the task has ended.
  var _finished = false;

  /// Whether the subscriber was ever attached to a running topic.
  var _registered = false;

  /// Whether the subscriber was told to stop.
  var _cancelled = false;

  /// Completes once [start] or [refuse] decided what the subscriber is.
  final _decided = Completer<Job>();

  /// Waits until the subscriber has ended.
  Future<void> get done => _decided.future.then((task) => task.join());

  /// Whether the subscriber is still receiving, which it stops doing the
  /// moment it is cancelled even if a handler is still running.
  bool get isActive => !_finished && !_cancelled;

  /// Whether the subscriber was attached to a running topic.
  bool get isRegistered => _registered;

  /// Starts receiving in a coroutine of [work], first the envelopes of
  /// [replay].
  void start(Iterable<EventEnvelope<Event>> replay, CoroutineScope work) {
    _registered = true;
    replay.forEach(_mailbox.trySend);
    final Job task = work.launch(
      (it) => _run(),
      start: CoroutineStart.undispatched,
    );
    _decided.complete(task);
  }

  /// Ends the subscriber before it ever received anything, because its
  /// topic was already closed.
  void refuse() {
    _finished = true;
    _mailbox.cancel();
    _decided.complete(CompletableJob()..complete());
  }

  /// Hands [envelope] to this subscriber, waiting until it is taken.
  ///
  /// Returns `false` if the subscriber ended in the meantime.
  Future<bool> offer(EventEnvelope<Event> envelope) => _mailbox.send(envelope);

  /// Stops the subscriber after the envelope it is handling, dropping what
  /// it has not taken yet.
  void cancel() {
    _cancelled = true;
    _mailbox.cancel();
  }

  /// Works through the mailbox until it is cancelled, or until the first
  /// matching envelope when the subscriber is a one-off.
  Future<void> _run() async {
    try {
      while (true) {
        final EventEnvelope<Event>? envelope = await _mailbox.receive();
        if (envelope == null) {
          return;
        }
        final bool consumed = await _consume(envelope);
        if (consumed && _once) {
          return;
        }
      }
    } finally {
      _finished = true;
      _mailbox.cancel();
      _detach(this);
    }
  }
}
