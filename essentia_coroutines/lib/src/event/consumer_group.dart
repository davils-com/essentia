/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/event/group_mailboxes.dart';
import 'package:meta/meta.dart';

/// A handle on a set of workers that share out a topic's envelopes between
/// them.
///
/// Where a subscription is told everything, a group is told each envelope
/// once: exactly one of its workers handles it. That is the difference
/// between watching a topic and working through it, and a topic can have
/// both attached at the same time without either noticing the other.
///
/// A group runs one worker per partition, so how wide it runs is decided by
/// the topic rather than here: a group cannot outrun the ordering guarantee
/// it sits behind.
final class ConsumerGroup {
  /// Creates the handle of the group [name] working through [_mailboxes],
  /// which [_detach] takes off its topic.
  @internal
  const ConsumerGroup(this.name, this._mailboxes, this._detach);

  /// What this group is called, which is the name its work is reported
  /// under to the bus's listener.
  final String name;

  /// The mailboxes and workers of the group.
  final GroupMailboxes _mailboxes;

  /// Stops the topic from sending to the group.
  final void Function() _detach;

  /// How many envelopes this group can be handling at once, which is
  /// always its topic's partition count.
  int get workerCount => _mailboxes.workerCount;

  /// Whether this group is still being given work.
  bool get isActive => _mailboxes.isActive;

  /// Detaches this group and stops its workers without waiting for what they
  /// hold.
  ///
  /// The topic stops sending to it immediately. Anything already in its
  /// mailboxes is reported to the listener rather than lost quietly.
  void cancel() {
    _detach();
    _mailboxes
      ..close()
      ..disposeBuffered()
      ..cancel();
  }

  /// Detaches this group and completes once its workers have finished what
  /// they hold.
  ///
  /// The orderly counterpart of [cancel]: the topic stops sending, and
  /// everything already in the mailboxes is handled before this completes.
  Future<void> drain() {
    _detach();
    _mailboxes.close();
    return _mailboxes.join();
  }
}
