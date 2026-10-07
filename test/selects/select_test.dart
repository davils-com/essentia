/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/essentia.dart';
import 'package:essentia/testing.dart';
import 'package:test/test.dart';

/// A channel of [capacity] holding [elements].
///
/// Returns the channel.
Channel<String> _holding(List<String> elements, {int capacity = 4}) {
  final channel = Channel<String>(capacity: capacity);
  elements.forEach(channel.trySend);
  return channel;
}

/// Covers `select` and its clauses: which clause wins, what a losing
/// clause leaves alone, failing clauses, and the clauses of deferreds,
/// jobs, futures and timeouts.
void main() {
  test(
    'the first clause that is ready wins and the others take nothing',
    () => runTest((it) async {
      final Channel<String> first = _holding(<String>['a']);
      final Channel<String> second = _holding(<String>['b']);

      final String chosen = await select<String>((it) {
        it
          ..onReceive(first, (value) => 'first $value')
          ..onReceive(second, (value) => 'second $value');
      });

      expect(chosen, 'first a');
      expect(second.tryReceive(), const ChannelSuccess('b'));
    }),
  );

  test(
    'a select waits for the first clause to become ready',
    () => runTest((it) async {
      final first = Channel<String>();
      final second = Channel<String>();
      it.launch((it) async {
        await delay(const Duration(seconds: 1));
        await second.send('late');
      });

      final String chosen = await select<String>((it) {
        it
          ..onReceive(first, (value) => 'first $value')
          ..onReceive(second, (value) => 'second $value');
      });

      expect(chosen, 'second late');
      expect(it.currentTime, const Duration(seconds: 1));
      expect(first.trySend('x'), const ChannelFailure<void>());
    }),
  );

  test(
    'clauses can be registered through invoke',
    () => runTest((it) async {
      final Channel<String> channel = _holding(<String>['a']);

      final int length = await select<int>(
        (it) => it.invoke(channel.onReceive, (value) => value.length),
      );

      expect(length, 1);
    }),
  );

  test(
    'receiving from a closed channel makes the select throw',
    () => runTest((it) async {
      final closed = Channel<String>()..close();
      final cause = Exception('broken');
      final failed = Channel<String>()..close(cause);

      await expectLater(
        select<String>((it) => it.onReceive(closed, (value) => value)),
        throwsA(isA<ClosedReceiveChannelException>()),
      );
      await expectLater(
        select<String>((it) => it.onReceive(failed, (value) => value)),
        throwsA(same(cause)),
      );
    }),
  );

  test(
    'a waiting receive clause selects the closure of its channel',
    () => runTest((it) async {
      final channel = Channel<String>();
      final Future<ChannelResult<String>> catching = select((it) {
        it.onReceiveCatching(channel, (result) => result);
      });
      final Future<void> receiving = expectLater(
        select<String>((it) => it.onReceive(channel, (value) => value)),
        throwsA(isA<ClosedReceiveChannelException>()),
      );

      channel.close();

      expect(await catching, const ChannelClosed<String>(null));
      await receiving;
    }),
  );

  test(
    'a send clause wins once the channel takes the element',
    () => runTest((it) async {
      final buffered = Channel<String>(capacity: 1);
      final rendezvous = Channel<String>();
      final Deferred<String> receiver = it.async((it) => rendezvous.receive());

      final SendChannel<String> taken = await select<SendChannel<String>>(
        (it) => it.onSend(buffered, 'kept', (channel) => channel),
      );
      await yieldNow();
      final String handedOver = await select<String>(
        (it) => it.onSend(rendezvous, 'met', (channel) => 'sent'),
      );

      expect(identical(taken, buffered), isTrue);
      expect(buffered.tryReceive(), const ChannelSuccess('kept'));
      expect(handedOver, 'sent');
      expect(await receiver, 'met');
    }),
  );

  test(
    'a waiting send clause wins once a receiver comes',
    () => runTest((it) async {
      final channel = Channel<String>();
      final Deferred<String> sending = it.async(
        (it) => select<String>(
          (it) => it.onSend(channel, 'hello', (channel) => 'sent'),
        ),
      );
      await yieldNow();

      expect(await channel.receive(), 'hello');
      expect(await sending, 'sent');
    }),
  );

  test(
    'a send clause on a conflated channel is always ready',
    () => runTest((it) async {
      final dropped = <String>[];
      final channel = Channel<String>(
        capacity: Channel.conflated,
        onUndeliveredElement: dropped.add,
      )..trySend('old');

      await select<void>((it) => it.onSend(channel, 'new', (channel) {}));

      expect(dropped, <String>['old']);
      expect(channel.tryReceive(), const ChannelSuccess('new'));
    }),
  );

  test(
    'a send clause on a channel dropping the latest takes the element',
    () => runTest((it) async {
      final dropped = <String>[];
      final channel = Channel<String>(
        capacity: 1,
        onBufferOverflow: BufferOverflow.dropLatest,
        onUndeliveredElement: dropped.add,
      )..trySend('kept');

      await select<void>((it) => it.onSend(channel, 'dropped', (channel) {}));

      expect(dropped, isEmpty);
      expect(channel.tryReceive(), const ChannelSuccess('kept'));
    }),
  );

  test(
    'a send clause on a closed channel throws and reports its element',
    () => runTest((it) async {
      final dropped = <String>[];
      final cause = Exception('gone');
      final channel = Channel<String>(onUndeliveredElement: dropped.add)
        ..close(cause);

      await expectLater(
        select<void>((it) => it.onSend(channel, 'lost', (channel) {})),
        throwsA(same(cause)),
      );
      expect(dropped, <String>['lost']);
    }),
  );

  test(
    'a waiting send clause fails when its channel is cancelled',
    () => runTest((it) async {
      final dropped = <String>[];
      final channel = Channel<String>(onUndeliveredElement: dropped.add);
      final Future<void> sending = expectLater(
        select<void>((it) => it.onSend(channel, 'lost', (channel) {})),
        throwsA(isA<CancellationException>()),
      );

      channel.cancel();

      await sending;
      expect(dropped, <String>['lost']);
    }),
  );

  test(
    'an await clause selects the value of a deferred',
    () => runTest((it) async {
      final done = CompletableDeferred<int>()..complete(1);
      final later = CompletableDeferred<int>();
      it.launch((it) async {
        await delay(const Duration(seconds: 2));
        later.complete(2);
      });

      final int first = await select<int>(
        (it) => it.onAwait(done, (value) => value),
      );
      final int second = await select<int>(
        (it) => it.onAwait(later, (value) => value * 10),
      );

      expect(first, 1);
      expect(second, 20);
      expect(it.currentTime, const Duration(seconds: 2));
    }),
  );

  test(
    'an await clause on a failed deferred makes the select throw',
    () => runTest((it) async {
      final failed = CompletableDeferred<int>()
        ..completeExceptionally(StateError('no value'));

      await expectLater(
        select<int>((it) => it.onAwait(failed, (value) => value)),
        throwsStateError,
      );
    }),
  );

  test(
    'an await clause starts a lazily started deferred',
    () => runTest((it) async {
      final Deferred<String> lazy = it.async(
        start: CoroutineStart.lazy,
        (it) => 'started',
      );

      final String value = await select<String>(
        (it) => it.onAwait(lazy, (value) => value),
      );

      expect(value, 'started');
    }),
  );

  test(
    'a join clause wins once the job is complete',
    () => runTest((it) async {
      final complete = CompletableJob()..complete();
      final Job lazy = it.launch(start: CoroutineStart.lazy, (it) async {
        await delay(const Duration(seconds: 3));
      });

      final String first = await select<String>(
        (it) => it.onJoin(complete, () => 'complete'),
      );
      final String second = await select<String>(
        (it) => it.onJoin(lazy, () => 'joined'),
      );

      expect(first, 'complete');
      expect(second, 'joined');
      expect(it.currentTime, const Duration(seconds: 3));
    }),
  );

  test(
    'a future clause selects the value or the failure of a future',
    () => runTest((it) async {
      final String value = await select<String>(
        (it) => it.onFuture(Future<String>.value('plain'), (value) => value),
      );

      expect(value, 'plain');
      await expectLater(
        select<String>(
          (it) => it.onFuture(
            Future<String>.error(StateError('failed')),
            (value) => value,
          ),
        ),
        throwsStateError,
      );
    }),
  );

  test(
    'a future that completes after another clause won is ignored',
    () => runTest((it) async {
      final pending = Completer<String>();
      final Channel<String> channel = _holding(<String>['ready']);

      final String chosen = await select<String>((it) {
        it
          ..onFuture(pending.future, (value) => 'future $value')
          ..onReceive(channel, (value) => 'channel $value');
      });
      pending.complete('late');
      await yieldNow();

      expect(chosen, 'channel ready');
    }),
  );

  test(
    'a timeout clause wins once its time passed on virtual time',
    () => runTest((it) async {
      final channel = Channel<String>();

      final String chosen = await select<String>((it) {
        it
          ..onReceive(channel, (value) => value)
          ..onTimeout(const Duration(seconds: 5), () => 'timed out');
      });

      expect(chosen, 'timed out');
      expect(it.currentTime, const Duration(seconds: 5));
    }),
  );

  test(
    'a timeout of zero is ready at once but loses to an earlier clause',
    () => runTest((it) async {
      final Channel<String> channel = _holding(<String>['ready']);

      final String immediate = await select<String>(
        (it) => it.onTimeout(Duration.zero, () => 'now'),
      );
      final String earlier = await select<String>((it) {
        it
          ..onReceive(channel, (value) => value)
          ..onTimeout(Duration.zero, () => 'now');
      });

      expect(immediate, 'now');
      expect(earlier, 'ready');
    }),
  );

  test(
    'a timeout that lost is called off',
    () => runTest((it) async {
      final Channel<String> channel = _holding(<String>[]);
      it.launch((it) async {
        await delay(const Duration(seconds: 1));
        channel.trySend('first');
      });

      final String chosen = await select<String>((it) {
        it
          ..onReceive(channel, (value) => value)
          ..onTimeout(const Duration(hours: 1), () => 'timed out');
      });
      it.advanceUntilIdle();

      expect(chosen, 'first');
      expect(it.currentTime, const Duration(seconds: 1));
    }),
  );

  test(
    'the block of the winner may wait and fail',
    () => runTest((it) async {
      final Channel<String> channel = _holding(<String>['a', 'b']);

      final String waited = await select<String>(
        (it) => it.onReceive(channel, (value) async {
          await delay(const Duration(seconds: 1));
          return 'waited for $value';
        }),
      );

      expect(waited, 'waited for a');
      await expectLater(
        select<String>(
          (it) => it.onReceive(channel, (value) => throw StateError(value)),
        ),
        throwsStateError,
      );
      expect(channel.isEmpty, isTrue);
    }),
  );

  test(
    'a builder that throws registers nothing',
    () => runTest((it) async {
      final channel = Channel<String>();

      await expectLater(
        select<String>((it) {
          it.onReceive(channel, (value) => value);
          throw StateError('broken builder');
        }),
        throwsStateError,
      );
      expect(channel.trySend('x'), const ChannelFailure<void>());
    }),
  );

  test(
    'a clause that fails while it registers ends the select',
    () => runTest((it) async {
      final waiting = Channel<String>();
      final closed = Channel<String>(
        onUndeliveredElement: (element) => throw StateError('cannot drop'),
      )..close();

      await expectLater(
        select<String>((it) {
          it
            ..onReceive(waiting, (value) => value)
            ..onSend(closed, 'x', (channel) => 'sent');
        }),
        throwsStateError,
      );
      expect(waiting.trySend('y'), const ChannelFailure<void>());
    }),
  );

  test(
    'an unbiased select lets every ready clause win sometimes',
    () => runTest((it) async {
      final wins = <String, int>{'first': 0, 'second': 0};
      for (var round = 0; round < 200; round++) {
        final Channel<String> first = _holding(<String>['first']);
        final Channel<String> second = _holding(<String>['second']);
        final String winner = await selectUnbiased<String>((it) {
          it
            ..onReceive(first, (value) => value)
            ..onReceive(second, (value) => value);
        });
        wins[winner] = wins[winner]! + 1;
      }

      expect(wins['first'], greaterThan(0));
      expect(wins['second'], greaterThan(0));
    }),
  );
}
