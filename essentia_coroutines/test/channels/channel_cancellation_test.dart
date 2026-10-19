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
import 'package:essentia_coroutines/testing.dart';
import 'package:test/test.dart';

/// Covers cancelling the work that waits on a channel: a cancelled sender
/// or receiver leaves the queue, and no element is lost on the way.
void main() {
  test(
    'a cancelled waiting sender leaves and reports its element',
    () => runTest((it) async {
      final dropped = <int>[];
      final channel = Channel<int>(onUndeliveredElement: dropped.add);
      final Job sender = it.launch((it) => channel.send(1));
      final Job other = it.launch((it) => channel.send(2));
      await yieldNow();

      await sender.cancelAndJoin();

      expect(dropped, <int>[1]);
      expect(await channel.receive(), 2);
      await other.join();
      expect(channel.isEmpty, isTrue);
    }),
  );

  test(
    'a cancelled waiting receiver leaves without taking anything',
    () => runTest((it) async {
      final channel = Channel<int>();
      final Deferred<int> first = it.async((it) => channel.receive());
      final Deferred<int> second = it.async((it) => channel.receive());
      await yieldNow();

      await first.cancelAndJoin();
      channel.trySend(7);

      expect(await second, 7);
      expect(first.isCancelled, isTrue);
    }),
  );

  test(
    'a receiver cancelled after the hand over reports the element',
    () => runTest((it) async {
      final dropped = <int>[];
      final channel = Channel<int>(onUndeliveredElement: dropped.add);
      final Deferred<int> receiver = it.async((it) => channel.receive());
      await yieldNow();

      channel.trySend(5);
      receiver.cancel();

      await expectLater(receiver, throwsA(isA<CancellationException>()));
      expect(dropped, <int>[5]);
    }),
  );

  test(
    'a send that has to wait in a cancelled job reports its element',
    () => runTest((it) async {
      final dropped = <int>[];
      final channel = Channel<int>(onUndeliveredElement: dropped.add);
      final Deferred<void> sender = it.async((it) async {
        it.cancel();
        await channel.send(1);
      });

      await expectLater(sender, throwsA(isA<CancellationException>()));

      expect(dropped, <int>[1]);
      expect(channel.isEmpty, isTrue);
    }),
  );

  test(
    'a receive that has to wait in a cancelled job takes nothing',
    () => runTest((it) async {
      final channel = Channel<int>(capacity: 1);
      final Deferred<int> receiver = it.async((it) {
        it.cancel();
        return channel.receive();
      });

      await expectLater(receiver, throwsA(isA<CancellationException>()));
      channel.trySend(1);

      expect(channel.tryReceive(), const ChannelSuccess(1));
    }),
  );

  test(
    'a waiting sender is cancelled with its scope',
    () => runTest((it) async {
      final dropped = <int>[];
      final channel = Channel<int>(onUndeliveredElement: dropped.add);
      final scope = CoroutineScope(Job());
      final Job sender = scope.launch((it) => channel.send(3));
      await yieldNow();

      scope.cancel();
      await sender.join();

      expect(dropped, <int>[3]);
      expect(channel.trySend(4), const ChannelFailure<void>());
    }),
  );
}
