/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_coroutines/testing.dart';
import 'package:test/test.dart';

/// A channel of [capacity] holding [elements], open unless [closed].
///
/// Returns the channel.
Channel<int> _holding(
  List<int> elements, {
  int capacity = 8,
  bool closed = true,
  void Function(int element)? onUndeliveredElement,
}) {
  final channel = Channel<int>(
    capacity: capacity,
    onUndeliveredElement: onUndeliveredElement,
  );
  elements.forEach(channel.trySend);
  if (closed) {
    channel.close();
  }
  return channel;
}

/// Covers the stream bridges of a channel - `receiveAsStream`,
/// `consumeAsStream` and `produceIn` - and `consumeEach` and `consume`.
void main() {
  test(
    'a channel received as a stream delivers every element and ends',
    () => runTest((it) async {
      final Channel<int> channel = _holding(<int>[1, 2, 3]);

      expect(await channel.receiveAsStream().toList(), <int>[1, 2, 3]);
    }),
  );

  test(
    'a stream of a channel closed with a cause ends with that error',
    () => runTest((it) async {
      final cause = Exception('upstream');
      final Channel<int> channel = _holding(<int>[1], closed: false)
        ..close(cause);

      await expectLater(
        channel.receiveAsStream(),
        emitsInOrder(<Object>[1, emitsError(same(cause)), emitsDone]),
      );
    }),
  );

  test(
    'listeners of the stream share the elements',
    () => runTest((it) async {
      final channel = Channel<int>();
      final Stream<int> stream = channel.receiveAsStream();
      final Future<List<int>> first = stream.toList();
      final Future<List<int>> second = stream.toList();
      await yieldNow();
      for (var element = 0; element < 10; element++) {
        await channel.send(element);
      }
      channel.close();

      final List<int> firstElements = await first;
      final List<int> secondElements = await second;

      expect(firstElements, isNotEmpty);
      expect(secondElements, isNotEmpty);
      expect(
        <int>[...firstElements, ...secondElements]..sort(),
        List<int>.generate(10, (index) => index),
      );
    }),
  );

  test(
    'a listener that cancels leaves the next element in the channel',
    () => runTest((it) async {
      final Channel<int> channel = _holding(<int>[1, 2], closed: false);

      final int first = await channel.receiveAsStream().first;

      expect(first, 1);
      expect(channel.tryReceive(), const ChannelSuccess(2));
    }),
  );

  test(
    'a waiting listener that cancels takes nothing',
    () => runTest((it) async {
      final channel = Channel<int>();
      final StreamSubscription<int> subscription = channel
          .receiveAsStream()
          .listen((element) {});
      await yieldNow();
      final bool sentWhileListening = channel.trySend(1).isSuccess;

      await subscription.cancel();
      await yieldNow();

      expect(sentWhileListening, isTrue);
      expect(channel.trySend(2), const ChannelFailure<void>());
    }),
  );

  test(
    'a paused listener takes nothing until it resumes',
    () => runTest((it) async {
      final channel = Channel<int>();
      final received = <int>[];
      final StreamSubscription<int> subscription = channel
          .receiveAsStream()
          .listen(received.add);
      await yieldNow();

      subscription.pause();
      await yieldNow();
      final ChannelResult<void> whilePaused = channel.trySend(1);
      subscription.resume();
      await yieldNow();
      final ChannelResult<void> afterResume = channel.trySend(2);
      await yieldNow();
      await subscription.cancel();

      expect(whilePaused, const ChannelFailure<void>());
      expect(afterResume, const ChannelSuccess<void>(null));
      expect(received, <int>[2]);
    }),
  );

  test(
    'a listener paused right after an element waits before the next one',
    () => runTest((it) async {
      final Channel<int> channel = _holding(<int>[1, 2], closed: false);
      final received = <int>[];
      final subscriptions = <StreamSubscription<int>>[];
      subscriptions.add(
        channel.receiveAsStream().listen((element) {
          received.add(element);
          subscriptions.single.pause();
        }),
      );
      await yieldNow();
      final receivedWhilePaused = List<int>.of(received);

      subscriptions.single.resume();
      await yieldNow();
      await subscriptions.single.cancel();

      expect(receivedWhilePaused, <int>[1]);
      expect(received, <int>[1, 2]);
    }),
  );

  test(
    'the stream of a cancelled listener ends with the cancellation',
    () => runTest((it) async {
      final channel = Channel<int>();
      final Deferred<List<int>> collecting = it.async(
        (it) => channel.receiveAsStream().toList(),
      );
      await yieldNow();

      collecting.cancel();

      await expectLater(collecting, throwsA(isA<CancellationException>()));
      expect(channel.trySend(1), const ChannelFailure<void>());
    }),
  );

  test(
    'a consumed stream ends with the channel and cancels it',
    () => runTest((it) async {
      final Channel<int> channel = _holding(<int>[1, 2]);

      expect(await channel.consumeAsStream().toList(), <int>[1, 2]);
      expect(channel.isClosedForReceive, isTrue);
    }),
  );

  test(
    'a consumed stream whose listener cancels cancels the channel',
    () => runTest((it) async {
      final dropped = <int>[];
      final Channel<int> channel = _holding(
        <int>[1, 2, 3],
        closed: false,
        onUndeliveredElement: dropped.add,
      );

      final int first = await channel.consumeAsStream().first;

      expect(first, 1);
      expect(dropped, <int>[2, 3]);
      expect(channel.isClosedForSend, isTrue);
    }),
  );

  test(
    'a consumed stream can be listened to once',
    () => runTest((it) async {
      final Channel<int> channel = _holding(<int>[1]);
      final Stream<int> stream = channel.consumeAsStream();
      final Future<List<int>> first = stream.toList();

      await expectLater(stream.toList(), throwsStateError);
      expect(await first, <int>[1]);
    }),
  );

  test(
    'consumeEach runs the action for every element, waiting for it',
    () => runTest((it) async {
      final Channel<int> channel = _holding(<int>[1, 2, 3]);
      final log = <String>[];

      await channel.consumeEach((element) async {
        await delay(const Duration(seconds: 1));
        log.add('$element at ${it.currentTime.inSeconds}');
      });

      expect(log, <String>['1 at 1', '2 at 2', '3 at 3']);
    }),
  );

  test(
    'consumeEach throws the close cause',
    () => runTest((it) async {
      final cause = Exception('failed');
      final Channel<int> channel = _holding(<int>[1], closed: false)
        ..close(cause);
      final received = <int>[];

      await expectLater(
        channel.consumeEach(received.add),
        throwsA(same(cause)),
      );
      expect(received, <int>[1]);
    }),
  );

  test(
    'a failing action cancels the channel with the failure as the cause',
    () => runTest((it) async {
      final dropped = <int>[];
      final Channel<int> channel = _holding(
        <int>[1, 2, 3],
        closed: false,
        onUndeliveredElement: dropped.add,
      );

      await expectLater(
        channel.consumeEach((element) => throw StateError('bad $element')),
        throwsStateError,
      );
      final Object? cause = channel.tryReceive().exceptionOrNull();

      expect(dropped, <int>[2, 3]);
      expect(
        cause,
        isA<CancellationException>().having(
          (exception) => exception.cause,
          'cause',
          isA<StateError>(),
        ),
      );
    }),
  );

  test(
    'consume hands back what its block returns and cancels the channel',
    () => runTest((it) async {
      final Channel<int> channel = _holding(<int>[4, 5], closed: false);

      final int first = await channel.consume((it) => it.receive());

      expect(first, 4);
      expect(channel.isClosedForSend, isTrue);
      expect(channel.isClosedForReceive, isTrue);
    }),
  );

  test(
    'consume passes a cancellation of its block on to the channel',
    () => runTest((it) async {
      final Channel<int> channel = _holding(<int>[], closed: false);
      const cause = CancellationException('stop');

      await expectLater(
        channel.consume<void>((it) => throw cause),
        throwsA(same(cause)),
      );
      expect(channel.tryReceive().exceptionOrNull(), same(cause));
    }),
  );

  test(
    'a stream produced into a channel delivers its events and closes it',
    () => runTest((it) async {
      final ReceiveChannel<int> channel = Stream<int>.fromIterable(<int>[
        1,
        2,
        3,
      ]).produceIn(it);
      final received = <int>[];

      await channel.consumeEach(received.add);

      expect(received, <int>[1, 2, 3]);
    }),
  );

  test(
    'a failing stream closes its channel with the error',
    () => runTest((it) async {
      final source = StreamController<int>();
      addTearDown(source.close);
      final ReceiveChannel<int> channel = source.stream.produceIn(
        CoroutineScope(SupervisorJob()),
      );
      source
        ..add(1)
        ..addError(StateError('broken'));

      expect(await channel.receive(), 1);
      await expectLater(channel.receive(), throwsStateError);
    }),
  );

  test(
    'a full channel pauses the stream and cancelling it cancels it',
    () => runTest((it) async {
      var cancelled = false;
      final source = StreamController<int>(onCancel: () => cancelled = true);
      addTearDown(source.close);
      final ReceiveChannel<int> channel = source.stream.produceIn(it);
      for (var element = 0; element < Channel.defaultCapacity + 2; element++) {
        source.add(element);
      }
      await yieldNow();
      final bool pausedWhileFull = source.isPaused;

      final int first = await channel.receive();
      channel.cancel();
      await yieldNow();

      expect(pausedWhileFull, isTrue);
      expect(first, 0);
      expect(cancelled, isTrue);
    }),
  );
}
