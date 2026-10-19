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
import 'package:essentia_coroutines/src/channels/receive_waiter.dart';
import 'package:essentia_coroutines/src/selects/select_instance.dart';
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
