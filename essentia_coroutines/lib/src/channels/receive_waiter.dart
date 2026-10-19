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

import 'dart:collection';

import 'package:essentia_coroutines/src/channels/channel_closed.dart';
import 'package:essentia_coroutines/src/channels/channel_result.dart';
import 'package:meta/meta.dart';

/// A receiver waiting until a channel hands it an element or is closed.
@internal
abstract base class ReceiveWaiter<E> extends LinkedListEntry<ReceiveWaiter<E>> {
  /// The select the waiter belongs to, `null` for a plain receive.
  Object? get owner => null;

  /// Hands [result] to the receiver: a [ChannelSuccess] with an element, or
  /// a [ChannelClosed] once nothing more will come.
  ///
  /// Returns `false` when the receiver is gone, so an element must stay in
  /// the channel.
  bool resume(ChannelResult<E> result);
}
