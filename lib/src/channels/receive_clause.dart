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
import 'package:essentia/src/selects/select_clause.dart';
import 'package:essentia/src/selects/select_instance.dart';
import 'package:meta/meta.dart';

/// The `onReceive` clause of a channel.
@internal
final class ReceiveClause<E> implements SelectClause<E> {
  /// Creates the clause receiving from [_channel].
  const ReceiveClause(this._channel);

  /// The channel received from.
  final BufferedChannel<E> _channel;

  /// See [SelectClause.register].
  @override
  void register(SelectInstance select) => _channel.registerReceive(select);

  /// The element received.
  ///
  /// Returns the element.
  ///
  /// Throws what `receive` throws on a channel closed for receive.
  @override
  E processResult(Object? result) =>
      _channel.valueOrThrow(result! as ChannelResult<E>);
}
