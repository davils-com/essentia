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

import 'package:essentia_coroutines/src/channels/buffered_channel.dart';
import 'package:essentia_coroutines/src/channels/channel_result.dart';
import 'package:essentia_coroutines/src/channels/send_channel.dart';
import 'package:essentia_coroutines/src/selects/select_clause.dart';
import 'package:essentia_coroutines/src/selects/select_instance.dart';
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
