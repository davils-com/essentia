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

/// Covers how selects meet on a channel: a select never pairs its own send
/// with its own receive, two selects pair with each other, and a select
/// that ends takes its clauses with it.
void main() {
  test(
    'a select never sends to its own receive',
    () => runTest((it) async {
      final channel = Channel<int>();
      final Deferred<String> selecting = it.async(
        (it) => select<String>((it) {
          it
            ..onSend(channel, 1, (channel) => 'sent')
            ..onReceive(channel, (value) => 'received $value');
        }),
      );
      await yieldNow();
      final bool waiting = !selecting.isCompleted;

      final int received = await channel.receive();

      expect(waiting, isTrue);
      expect(received, 1);
      expect(await selecting, 'sent');
      expect(channel.isEmpty, isTrue);
    }),
  );

  test(
    'a select never receives from its own send',
    () => runTest((it) async {
      final channel = Channel<int>();
      final Deferred<String> selecting = it.async(
        (it) => select<String>((it) {
          it
            ..onReceive(channel, (value) => 'received $value')
            ..onSend(channel, 1, (channel) => 'sent');
        }),
      );
      await yieldNow();

      await channel.send(5);

      expect(await selecting, 'received 5');
      expect(channel.trySend(6), const ChannelFailure<void>());
      expect(channel.tryReceive(), const ChannelFailure<int>());
    }),
  );

  test(
    'a select that buffers its own element drops its own receive',
    () => runTest((it) async {
      final channel = Channel<int>(capacity: 1);

      final String chosen = await select<String>((it) {
        it
          ..onReceive(channel, (value) => 'received $value')
          ..onSend(channel, 1, (channel) => 'sent');
      });

      expect(chosen, 'sent');
      expect(channel.tryReceive(), const ChannelSuccess(1));
      expect(channel.tryReceive(), const ChannelFailure<int>());
    }),
  );

  test(
    'a select that receives from a full channel drops its own send',
    () => runTest((it) async {
      final channel = Channel<int>(capacity: 1)..trySend(1);

      final String chosen = await select<String>((it) {
        it
          ..onSend(channel, 2, (channel) => 'sent')
          ..onReceive(channel, (value) => 'received $value');
      });

      expect(chosen, 'received 1');
      expect(channel.tryReceive(), const ChannelFailure<int>());
    }),
  );

  test(
    'a sending select and a receiving select pair with each other',
    () => runTest((it) async {
      final channel = Channel<int>();
      final other = Channel<int>();
      final Deferred<String> sending = it.async(
        (it) => select<String>((it) {
          it
            ..onReceive(other, (value) => 'other $value')
            ..onSend(channel, 7, (channel) => 'sent');
        }),
      );
      await yieldNow();

      final String receiving = await select<String>((it) {
        it
          ..onSend(other, 0, (channel) => 'other sent')
          ..onReceive(channel, (value) => 'received $value');
      });

      expect(receiving, 'other sent');
      expect(await sending, 'other 0');
      expect(channel.trySend(1), const ChannelFailure<void>());
    }),
  );

  test(
    'a waiting receiving select is resumed by a sending select',
    () => runTest((it) async {
      final channel = Channel<int>();
      final Deferred<String> receiving = it.async(
        (it) => select<String>(
          (it) => it.onReceive(channel, (value) => 'received $value'),
        ),
      );
      await yieldNow();

      final String sending = await select<String>(
        (it) => it.onSend(channel, 3, (channel) => 'sent'),
      );

      expect(sending, 'sent');
      expect(await receiving, 'received 3');
    }),
  );

  test(
    'cancelling a waiting select disposes every clause',
    () => runTest((it) async {
      final receiving = Channel<int>();
      final sending = Channel<int>();
      final deferred = CompletableDeferred<int>();
      final job = Job();
      final Deferred<String> selecting = it.async(
        (it) => select<String>((it) {
          it
            ..onReceive(receiving, (value) => 'received')
            ..onSend(sending, 1, (channel) => 'sent')
            ..onAwait(deferred, (value) => 'awaited')
            ..onJoin(job, () => 'joined')
            ..onTimeout(const Duration(hours: 1), () => 'timed out');
        }),
      );
      await yieldNow();

      await selecting.cancelAndJoin();
      deferred.complete(1);
      job.cancel();
      it.advanceUntilIdle();

      expect(selecting.isCancelled, isTrue);
      expect(receiving.trySend(1), const ChannelFailure<void>());
      expect(sending.tryReceive(), const ChannelFailure<int>());
      expect(it.currentTime, Duration.zero);
    }),
  );

  test(
    'an element handed to a select whose caller is cancelled is reported',
    () => runTest((it) async {
      final dropped = <int>[];
      final channel = Channel<int>(onUndeliveredElement: dropped.add);
      final Deferred<int> selecting = it.async(
        (it) => select<int>((it) => it.onReceive(channel, (value) => value)),
      );
      await yieldNow();

      channel.trySend(4);
      selecting.cancel();

      await expectLater(selecting, throwsA(isA<CancellationException>()));
      expect(dropped, <int>[4]);
    }),
  );

  test(
    'a select that has to wait in a cancelled job registers nothing',
    () => runTest((it) async {
      final channel = Channel<int>();
      final Deferred<int> selecting = it.async((it) {
        it.cancel();
        return select<int>((it) => it.onReceive(channel, (value) => value));
      });

      await expectLater(selecting, throwsA(isA<CancellationException>()));
      expect(channel.trySend(1), const ChannelFailure<void>());
    }),
  );

  test(
    'a select in a cancelled job takes a ready element without waiting',
    () => runTest((it) async {
      final channel = Channel<int>(capacity: 1)..trySend(9);
      final values = <int>[];
      it.launch((it) async {
        it.cancel();
        values.add(
          await select<int>((it) => it.onReceive(channel, (value) => value)),
        );
      });
      await yieldNow();

      expect(values, <int>[9]);
    }),
  );
}
