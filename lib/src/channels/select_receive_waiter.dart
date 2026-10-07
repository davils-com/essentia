/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/channels/buffered_channel.dart';
import 'package:essentia/src/channels/channel_result.dart';
import 'package:essentia/src/channels/receive_waiter.dart';
import 'package:essentia/src/selects/select_instance.dart';
import 'package:meta/meta.dart';

/// The waiter of an `onReceive` or `onReceiveCatching` clause, which
/// resumes by selecting the clause.
@internal
final class SelectReceiveWaiter<E> extends ReceiveWaiter<E> {
  /// Creates the waiter of a receive clause of [_select] on [_channel].
  SelectReceiveWaiter(this._channel, this._select);

  /// The channel the clause waits on.
  final BufferedChannel<E> _channel;

  /// The select the clause belongs to.
  final SelectInstance _select;

  /// See [ReceiveWaiter.owner].
  @override
  Object? get owner => _select.owner;

  /// Selects the clause with [result]; an element the caller of the select
  /// is cancelled before it takes goes to the channel's
  /// `onUndeliveredElement`.
  @override
  bool resume(ChannelResult<E> result) => _select.trySelect(
    result,
    onCancellation: () => _channel.undeliverResult(result),
  );
}
