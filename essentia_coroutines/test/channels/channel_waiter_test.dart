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

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_coroutines/src/channels/buffered_channel.dart';
import 'package:test/test.dart';

import 'ended_select.dart';

/// Covers the waiter queues of the channel: what it counts as waiting, and
/// that a waiter which can no longer take part is skipped and dropped
/// without taking an element.
void main() {
  test('counts the buffered elements and those of waiting senders', () {
    final channel = BufferedChannel<int>(capacity: 1)..trySend(1);
    final select = EndedSelect();

    final int buffered = channel.size;
    channel.registerSend(select, 2);

    expect(buffered, 1);
    expect(channel.size, 2);
  });

  test('a receiver that can no longer take part is skipped', () {
    final channel = BufferedChannel<int>(capacity: 1)
      ..registerReceive(EndedSelect());

    final ChannelResult<void> sent = channel.trySend(1);

    expect(sent, const ChannelSuccess<void>(null));
    expect(channel.tryReceive(), const ChannelSuccess(1));
  });

  test('a sender that can no longer take part is skipped', () {
    final channel = BufferedChannel<int>()..registerSend(EndedSelect(), 1);

    final ChannelResult<int> received = channel.tryReceive();

    expect(received, const ChannelFailure<int>());
    expect(channel.size, 0);
  });

  test('a sender that can no longer take part is not admitted', () {
    final channel = BufferedChannel<int>(capacity: 1)..trySend(1);
    final select = EndedSelect();
    channel.registerSend(select, 2);

    final ChannelResult<int> received = channel.tryReceive();

    expect(received, const ChannelSuccess(1));
    expect(channel.tryReceive(), const ChannelFailure<int>());
    expect(select.handles, hasLength(1));
  });
}
