/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:essentia/src/channels/buffered_channel.dart';
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
