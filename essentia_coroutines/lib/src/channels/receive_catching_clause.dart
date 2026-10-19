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
