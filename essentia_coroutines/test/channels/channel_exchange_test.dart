/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_coroutines/testing.dart';
import 'package:test/test.dart';

/// Covers how senders and receivers meet in a channel: rendezvous, a
/// bounded buffer, waiting senders and receivers served oldest first, and
/// nullable elements.
void main() {
  test(
    'a rendezvous send completes once a receiver took the element',
    () => runTest((it) async {
      final channel = Channel<String>();
      var sent = false;
      it.launch((it) async {
        await channel.send('hello');
        sent = true;
      });
      await yieldNow();
      final sentEarly = sent;
      final bool emptyWhileSending = channel.isEmpty;

      final String received = await channel.receive();
      await yieldNow();

      expect(sentEarly, isFalse);
      expect(emptyWhileSending, isFalse);
      expect(received, 'hello');
      expect(sent, isTrue);
    }),
  );

  test(
    'a receive waits until a sender delivers',
    () => runTest((it) async {
      final channel = Channel<int>();
      final Deferred<int> received = it.async((it) => channel.receive());
      await yieldNow();
      final bool waiting = !received.isCompleted;

      await channel.send(42);

      expect(waiting, isTrue);
      expect(await received, 42);
    }),
  );

  test(
    'a rendezvous element is taken from a waiting sender',
    () => runTest((it) async {
      final channel = Channel<int>();
      it.launch((it) => channel.send(5));
      await yieldNow();

      expect(channel.tryReceive(), const ChannelSuccess(5));
      expect(channel.tryReceive(), const ChannelFailure<int>());
    }),
  );

  test(
    'a full buffer makes senders wait and admits them in order',
    () => runTest((it) async {
      final channel = Channel<int>(capacity: 2);
      final sent = <int>[];
      for (var element = 0; element < 5; element++) {
        it.launch((it) async {
          await channel.send(element);
          sent.add(element);
        });
      }
      await yieldNow();
      final sentWhileFull = List<int>.of(sent);

      final received = <int>[];
      for (var index = 0; index < 5; index++) {
        received.add(await channel.receive());
      }
      await yieldNow();

      expect(sentWhileFull, <int>[0, 1]);
      expect(received, <int>[0, 1, 2, 3, 4]);
      expect(sent, <int>[0, 1, 2, 3, 4]);
      expect(channel.isEmpty, isTrue);
    }),
  );

  test(
    'waiting receivers are served oldest first',
    () => runTest((it) async {
      final channel = Channel<int>();
      final served = <String>[];
      for (final name in <String>['a', 'b', 'c']) {
        it.launch((it) async {
          served.add('$name:${await channel.receive()}');
        });
      }
      await yieldNow();

      for (var element = 1; element <= 3; element++) {
        expect(channel.trySend(element), const ChannelSuccess<void>(null));
      }
      await yieldNow();

      expect(served, <String>['a:1', 'b:2', 'c:3']);
    }),
  );

  test(
    'an element sent while receivers wait skips the buffer',
    () => runTest((it) async {
      final channel = Channel<int>(capacity: 4);
      final Deferred<int> received = it.async((it) => channel.receive());
      await yieldNow();

      channel.trySend(9);

      expect(channel.isEmpty, isTrue);
      expect(await received, 9);
    }),
  );

  test(
    'null is an element like any other',
    () => runTest((it) async {
      final channel = Channel<int?>(capacity: 2);
      await channel.send(null);
      await channel.send(1);
      channel.close();

      expect(await channel.receive(), isNull);
      expect(channel.tryReceive(), const ChannelSuccess<int?>(1));
      expect(await channel.receiveCatching(), const ChannelClosed<int?>(null));
      expect(channel.isClosedForReceive, isTrue);
    }),
  );

  test(
    'receiving catching hands out elements as successes',
    () => runTest((it) async {
      final channel = Channel<int>(capacity: 1);
      await channel.send(3);

      expect(await channel.receiveCatching(), const ChannelSuccess(3));
    }),
  );

  test(
    'a send with room completes even when its job is cancelled',
    () => runTest((it) async {
      final channel = Channel<int>(capacity: 1);
      var sent = false;
      it.launch((it) async {
        it.cancel();
        await channel.send(1);
        sent = true;
      });
      await yieldNow();

      expect(sent, isTrue);
      expect(channel.tryReceive(), const ChannelSuccess(1));
    }),
  );
}
