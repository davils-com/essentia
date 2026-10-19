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

/// Covers the `produce` builder: the producer closes its channel when it
/// completes or fails, cancelling the channel cancels the producer, and
/// `awaitClose` keeps a producer alive until its consumer is done.
void main() {
  test(
    'a producer closes its channel once its body completes',
    () => runTest((it) async {
      final ReceiveChannel<int> squares = it.produce((it) async {
        for (var x = 1; x <= 5; x++) {
          await it.send(x * x);
        }
      });
      final received = <int>[];

      await squares.consumeEach(received.add);

      expect(received, <int>[1, 4, 9, 16, 25]);
      expect(squares.isClosedForReceive, isTrue);
    }),
  );

  test(
    'a failing producer closes its channel with the failure',
    () => runTest((it) async {
      final scope = CoroutineScope(SupervisorJob());
      final ReceiveChannel<int> channel = scope.produce((it) async {
        await it.send(1);
        throw StateError('broken');
      });

      final int first = await channel.receive();

      expect(first, 1);
      await expectLater(channel.receive(), throwsStateError);
    }),
  );

  test(
    'a failing producer cancels its parent',
    () => runTest((it) async {
      final parent = Job();
      final ReceiveChannel<int> channel = CoroutineScope(parent)
          .produce((it) => throw StateError('broken'));

      await expectLater(channel.receive(), throwsStateError);
      await parent.join();

      expect(parent.isCancelled, isTrue);
    }),
  );

  test(
    'cancelling the channel cancels the producer',
    () => runTest((it) async {
      final log = <String>[];
      final ReceiveChannel<int> numbers = it.produce((it) async {
        try {
          for (var x = 0; ; x++) {
            await it.send(x);
          }
        } on CancellationException {
          log.add('cancelled');
          rethrow;
        }
      });

      final int first = await numbers.receive();
      numbers.cancel();
      await yieldNow();

      expect(first, 0);
      expect(log, <String>['cancelled']);
      expect(numbers.isClosedForReceive, isTrue);
    }),
  );

  test(
    'cancelling the parent closes the channel after its elements',
    () => runTest((it) async {
      final parent = Job();
      final ReceiveChannel<int> channel = CoroutineScope(parent)
          .produce((it) async {
            await it.send(1);
            await it.send(2);
            await awaitCancellation();
          }, capacity: 2);
      await yieldNow();

      parent.cancel();
      await parent.join();

      expect(await channel.receive(), 1);
      expect(await channel.receive(), 2);
      await expectLater(
        channel.receive(),
        throwsA(isA<CancellationException>()),
      );
    }),
  );

  test(
    'a producer waits in awaitClose until its consumer cancels',
    () => runTest((it) async {
      final log = <String>[];
      final ReceiveChannel<int> channel = it.produce((it) async {
        it.trySend(1);
        await it.awaitClose(() => log.add('released'));
      }, capacity: 1);

      final int first = await channel.receive();
      await yieldNow();
      final waitingLog = List<String>.of(log);
      channel.cancel();
      await yieldNow();

      expect(first, 1);
      expect(waitingLog, isEmpty);
      expect(log, <String>['released']);
    }),
  );

  test(
    'awaitClose returns once the producer closes the channel',
    () => runTest((it) async {
      final log = <String>[];
      final ReceiveChannel<int> channel = it.produce((it) async {
        final producer = it;
        it.launch((it) async {
          await delay(const Duration(seconds: 1));
          producer.close();
        });
        await it.awaitClose();
        log.add('closed at ${it.isActive}');
      });

      final ChannelResult<int> result = await channel.receiveCatching();
      await yieldNow();

      expect(result, const ChannelClosed<int>(null));
      expect(log, <String>['closed at true']);
      expect(it.currentTime, const Duration(seconds: 1));
    }),
  );

  test(
    'awaitClose refuses to run outside the producer',
    () => runTest((it) async {
      final producers = <ProducerScope<int>>[];
      final ReceiveChannel<int> channel = it.produce((it) async {
        producers.add(it);
        await awaitCancellation();
      });
      await yieldNow();

      await expectLater(producers.single.awaitClose(), throwsStateError);
      channel.cancel();
    }),
  );

  test(
    'the producer and its channel forward every operation',
    () => runTest((it) async {
      final closes = <Object?>[];
      final producers = <ProducerScope<int>>[];
      final ReceiveChannel<int> channel = it.produce((it) async {
        producers.add(it);
        it.invokeOnClose(closes.add);
        await it.send(1);
        it.trySend(2);
        await select<void>((select) => select.onSend(it, 3, (channel) {}));
        it.close();
      }, capacity: 3);
      final bool emptyAtFirst = channel.isEmpty;
      await yieldNow();

      expect(emptyAtFirst, isTrue);
      expect(channel.isEmpty, isFalse);
      expect(identical(producers.single.channel, producers.single), isTrue);
      expect(producers.single.isClosedForSend, isTrue);
      expect(channel.tryReceive(), const ChannelSuccess(1));
      expect(await channel.receive(), 2);
      expect(
        await select<int>((it) => it.onReceive(channel, (value) => value)),
        3,
      );
      expect(
        await select<ChannelResult<int>>(
          (it) => it.onReceiveCatching(channel, (result) => result),
        ),
        const ChannelClosed<int>(null),
      );
      expect(await channel.receiveCatching(), const ChannelClosed<int>(null));
      expect(channel.isClosedForReceive, isTrue);
      expect(closes, <Object?>[null]);
      expect(channel.toString(), startsWith('ProducerCoroutine('));
    }),
  );

  test(
    'a producer runs with the context and capacity it was given',
    () => runTest((it) async {
      final names = <String?>[];
      final ReceiveChannel<int> channel = it.produce(
        (it) async {
          names.add(currentCoroutineContext().get(CoroutineName.key)?.name);
          for (var x = 0; x < 3; x++) {
            await it.send(x);
          }
        },
        capacity: Channel.conflated,
        context: const CoroutineName('numbers'),
      );
      await yieldNow();

      expect(names, <String?>['numbers']);
      expect(await channel.receive(), 2);
    }),
  );

  test(
    'a failure the closed channel cannot carry is reported',
    () => runTest((it) async {
      final failures = <Object>[];
      final scope = CoroutineScope(
        SupervisorJob() +
            CoroutineExceptionHandler(
              (context, error, stackTrace) => failures.add(error),
            ),
      );
      final ReceiveChannel<int> channel = scope.produce((it) {
        it.close();
        throw StateError('late');
      });

      final ChannelResult<int> result = await channel.receiveCatching();
      await yieldNow();

      expect(result, const ChannelClosed<int>(null));
      expect(failures.single, isA<StateError>());
    }),
  );
}
