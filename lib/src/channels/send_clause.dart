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
import 'package:essentia/src/channels/send_channel.dart';
import 'package:essentia/src/selects/select_clause.dart';
import 'package:essentia/src/selects/select_instance.dart';
import 'package:meta/meta.dart';

/// The `onSend` clause of a channel, sending [_element].
@internal
final class SendClause<E> implements SelectClause<SendChannel<E>> {
  /// Creates the clause sending [_element] to [_channel].
  const SendClause(this._channel, this._element);

  /// The channel sent to.
  final BufferedChannel<E> _channel;

  /// The element sent.
  final E _element;

  /// See [SelectClause.register].
  @override
  void register(SelectInstance select) =>
      _channel.registerSend(select, _element);

  /// The channel, once it took the element.
  ///
  /// Returns the channel.
  ///
  /// Throws what `send` throws on a closed channel.
  @override
  SendChannel<E> processResult(Object? result) {
    final Object? failure = (result! as ChannelResult<void>).exceptionOrNull();
    if (failure != null) {
      Error.throwWithStackTrace(failure, StackTrace.current);
    }
    return _channel;
  }
}
