/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/channels/buffered_channel.dart';
import 'package:essentia_coroutines/src/channels/channel_result.dart';
import 'package:essentia_coroutines/src/selects/select_clause.dart';
import 'package:essentia_coroutines/src/selects/select_instance.dart';
import 'package:meta/meta.dart';

/// The `onReceiveCatching` clause of a channel.
@internal
final class ReceiveCatchingClause<E> implements SelectClause<ChannelResult<E>> {
  /// Creates the clause receiving from [_channel].
  const ReceiveCatchingClause(this._channel);

  /// The channel received from.
  final BufferedChannel<E> _channel;

  /// See [SelectClause.register].
  @override
  void register(SelectInstance select) => _channel.registerReceive(select);

  /// The element received, or the closure of the channel.
  ///
  /// Returns a `ChannelSuccess` or a `ChannelClosed`.
  @override
  ChannelResult<E> processResult(Object? result) => result! as ChannelResult<E>;
}
