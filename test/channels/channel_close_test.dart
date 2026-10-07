/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:essentia/testing.dart';
import 'package:test/test.dart';

/// Covers closing and cancelling a channel: what is still delivered, what
/// is dropped and reported, and what every side learns about it.
void main() {
  test('closing is done once and stops new sends', () {
    final channel = Channel<int>(capacity: 1);

    expect(channel.close(), isTrue);
    expect(channel.close(), isFalse);
    expect(channel.isClosedForSend, isTrue);
    expect(channel.isClosedForReceive, isTrue);
    expect(channel.isEmpty, isFalse);
  });

  test(
    'a closed channel still delivers buffered elements and senders',
    () => runTest((it) async {
      final channel = Channel<int>(capacity: 1);
      await channel.send(1);
      it.launch((it) => channel.send(2));
      await yieldNow();

      channel.close();
      final bool closedForReceiveEarly = channel.isClosedForReceive;

      expect(closedForReceiveEarly, isFalse);
      expect(await channel.receive(), 1);
      expect(await channel.receive(), 2);
      expect(channel.isClosedForReceive, isTrue);
      expect(channel.tryReceive(), const ChannelClosed<int>(null));
      await expectLater(
        channel.receive(),
        throwsA(isA<ClosedReceiveChannelException>()),
      );
    }),
  );

  test(
    'closing an empty channel releases its waiting receivers',
    () => runTest((it) async {
      final channel = Channel<int>();
      final Future<void> receiving = expectLater(
        channel.receive(),
        throwsA(isA<ClosedReceiveChannelException>()),
      );
      final Future<ChannelResult<int>> catching = channel.receiveCatching();
      final bool emptyWhileWaiting = channel.isEmpty;

      channel.close();

      await receiving;
      expect(await catching, const ChannelClosed<int>(null));
      expect(emptyWhileWaiting, isTrue);
    }),
  );

  test(
    'a close cause is what receivers and senders get',
    () => runTest((it) async {
      final dropped = <int>[];
      final channel = Channel<int>(onUndeliveredElement: dropped.add);
      final cause = Exception('upstream failed');
      final Future<void> receiving = expectLater(
        channel.receive(),
        throwsA(same(cause)),
      );

      channel.close(cause);

      await receiving;
      await expectLater(channel.send(1), throwsA(same(cause)));
      expect(channel.trySend(2), ChannelClosed<void>(cause));
      expect(await channel.receiveCatching(), ChannelClosed<int>(cause));
      expect(dropped, <int>[1]);
    }),
  );

  test('a send to a closed channel reports its element', () async {
    final dropped = <int>[];
    final channel = Channel<int>(onUndeliveredElement: dropped.add)..close();

    await expectLater(
      channel.send(1),
      throwsA(
        isA<ClosedSendChannelException>().having(
          (error) => error.toString(),
          'toString',
          'ClosedSendChannelException: Channel was closed',
        ),
      ),
    );
    final ChannelResult<void> refused = channel.trySend(2);

    expect(dropped, <int>[1]);
    expect(refused.isClosed, isTrue);
    expect(refused.exceptionOrNull(), isA<ClosedSendChannelException>());
  });

  test('a closed receive renders its message', () {
    expect(
      ClosedReceiveChannelException().toString(),
      'ClosedReceiveChannelException: Channel was closed',
    );
  });

  test(
    'cancelling drops and reports everything the channel holds',
    () => runTest((it) async {
      final dropped = <int>[];
      final channel = Channel<int>(
        capacity: 2,
        onUndeliveredElement: dropped.add,
      );
      await channel.send(1);
      await channel.send(2);
      final Deferred<void> waiting = it.async((it) => channel.send(3));
      await yieldNow();

      channel.cancel();

      await expectLater(waiting, throwsA(isA<CancellationException>()));
      expect(dropped, <int>[1, 2, 3]);
      expect(channel.isClosedForReceive, isTrue);
      expect(channel.isClosedForSend, isTrue);
      await expectLater(
        channel.receive(),
        throwsA(isA<CancellationException>()),
      );
      expect(
        channel.tryReceive().exceptionOrNull(),
        isA<CancellationException>(),
      );
    }),
  );

  test(
    'cancelling releases waiting receivers with the cause',
    () => runTest((it) async {
      final channel = Channel<int>();
      const cause = CancellationException('no longer needed');
      final Future<void> receiving = expectLater(
        channel.receive(),
        throwsA(same(cause)),
      );

      channel.cancel(cause);

      await receiving;
    }),
  );

  test('cancelling a closed channel keeps the close cause', () {
    final dropped = <int>[];
    final channel = Channel<int>(capacity: 2, onUndeliveredElement: dropped.add)
      ..trySend(1)
      ..close(StateError('closed first'))
      ..cancel();

    expect(dropped, <int>[1]);
    expect(channel.tryReceive().exceptionOrNull(), isA<StateError>());
  });

  test('every element is reported even when reporting fails', () {
    final dropped = <int>[];
    final channel =
        Channel<int>(
            capacity: 3,
            onUndeliveredElement: (element) {
              dropped.add(element);
              if (element.isEven) {
                throw StateError('cannot release $element');
              }
            },
          )
          ..trySend(1)
          ..trySend(2)
          ..trySend(4);

    expect(
      channel.cancel,
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'cannot release 2',
        ),
      ),
    );
    expect(dropped, <int>[1, 2, 4]);
  });

  test('the close handler runs once with the cause', () {
    final causes = <Object?>[];
    final channel = Channel<int>()..invokeOnClose(causes.add);
    final cause = Exception('stop');

    channel
      ..close(cause)
      ..close()
      ..cancel();

    expect(causes, <Object?>[cause]);
  });

  test('the close handler runs at once on a closed channel', () {
    final causes = <Object?>[];
    Channel<int>()
      ..close()
      ..invokeOnClose(causes.add);

    expect(causes, <Object?>[null]);
  });

  test('the close handler runs when the channel is cancelled', () {
    final causes = <Object?>[];
    Channel<int>()
      ..invokeOnClose(causes.add)
      ..cancel();

    expect(causes.single, isA<CancellationException>());
  });

  test('a channel takes one close handler only', () {
    final channel = Channel<int>()..invokeOnClose((cause) {});

    expect(() => channel.invokeOnClose((cause) {}), throwsStateError);
  });
}
