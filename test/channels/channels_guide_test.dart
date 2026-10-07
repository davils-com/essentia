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

import 'ball.dart';

/// Produces the squares of one to five, like `produceSquares` of the guide.
///
/// Returns the channel of squares.
ReceiveChannel<int> _produceSquares(CoroutineScope scope) =>
    scope.produce((it) async {
      for (var x = 1; x <= 5; x++) {
        await it.send(x * x);
      }
    });

/// Produces the numbers from [start] on, like `numbersFrom` of the guide.
///
/// Returns the channel of numbers.
ReceiveChannel<int> _numbersFrom(CoroutineScope scope, int start) =>
    scope.produce((it) async {
      for (var x = start; ; x++) {
        await it.send(x);
      }
    });

/// Passes on the numbers of [numbers] that [prime] does not divide, like
/// `filter` of the guide.
///
/// Returns the channel of the numbers passed on.
ReceiveChannel<int> _filter(
  CoroutineScope scope,
  ReceiveChannel<int> numbers,
  int prime,
) => scope.produce((it) async {
  await for (final int x in numbers.receiveAsStream()) {
    if (x % prime != 0) {
      await it.send(x);
    }
  }
});

/// Sends [text] to [channel] every [period], like `sendString` of the
/// guide.
///
/// Returns a future that never completes normally.
Future<void> _sendString(
  SendChannel<String> channel,
  String text,
  Duration period,
) async {
  while (true) {
    await delay(period);
    await channel.send(text);
  }
}

/// Plays ping-pong as [name] on [table], logging every hit to [log], like
/// `player` of the guide.
///
/// Returns a future that completes once the table is closed.
Future<void> _player(String name, Channel<Ball> table, List<String> log) async {
  await for (final Ball ball in table.receiveAsStream()) {
    ball.hits++;
    log.add('$name $ball');
    await delay(const Duration(milliseconds: 300));
    await table.send(ball);
  }
}

/// Covers the examples of the "Channels" chapter of the kotlinx.coroutines
/// guide, ported to Dart; each asserts the whole output of its example.
void main() {
  test(
    'channel basics',
    () => runTest((it) async {
      final log = <String>[];
      final channel = Channel<int>();
      it.launch((it) async {
        for (var x = 1; x <= 5; x++) {
          await channel.send(x * x);
        }
      });
      for (var index = 0; index < 5; index++) {
        log.add('${await channel.receive()}');
      }
      log.add('Done!');

      expect(log, <String>['1', '4', '9', '16', '25', 'Done!']);
    }),
  );

  test(
    'closing and iteration over channels',
    () => runTest((it) async {
      final log = <String>[];
      final channel = Channel<int>();
      it.launch((it) async {
        for (var x = 1; x <= 5; x++) {
          await channel.send(x * x);
        }
        channel.close();
      });
      await for (final int y in channel.receiveAsStream()) {
        log.add('$y');
      }
      log.add('Done!');

      expect(log, <String>['1', '4', '9', '16', '25', 'Done!']);
    }),
  );

  test(
    'building channel producers',
    () => runTest((it) async {
      final log = <String>[];
      final ReceiveChannel<int> squares = _produceSquares(it);
      await squares.consumeEach((element) => log.add('$element'));
      log.add('Done!');

      expect(log, <String>['1', '4', '9', '16', '25', 'Done!']);
    }),
  );

  test(
    'pipelines',
    () => runTest((it) async {
      final log = <String>[];
      final ReceiveChannel<int> numbers = _numbersFrom(it, 1);
      final ReceiveChannel<int> squares = it.produce((it) async {
        await for (final int x in numbers.receiveAsStream()) {
          await it.send(x * x);
        }
      });
      for (var index = 0; index < 5; index++) {
        log.add('${await squares.receive()}');
      }
      log.add('Done!');
      it.coroutineContext.cancelChildren();

      expect(log, <String>['1', '4', '9', '16', '25', 'Done!']);
    }),
  );

  test(
    'prime numbers with pipeline',
    () => runTest((it) async {
      final log = <String>[];
      ReceiveChannel<int> current = _numbersFrom(it, 2);
      for (var index = 0; index < 10; index++) {
        final int prime = await current.receive();
        log.add('$prime');
        current = _filter(it, current, prime);
      }
      it.coroutineContext.cancelChildren();

      expect(log, <String>[
        '2',
        '3',
        '5',
        '7',
        '11',
        '13',
        '17',
        '19',
        '23',
        '29',
      ]);
    }),
  );

  test(
    'fan-out',
    () => runTest((it) async {
      final log = <String>[];
      final ReceiveChannel<int> producer = it.produce((it) async {
        for (var x = 1; ; x++) {
          await it.send(x);
          await delay(const Duration(milliseconds: 100));
        }
      });
      for (var id = 0; id < 5; id++) {
        it.launch((it) async {
          await for (final int message in producer.receiveAsStream()) {
            log.add('Processor #$id received $message');
          }
        });
      }
      await delay(const Duration(milliseconds: 950));
      producer.cancel();

      expect(log, <String>[
        'Processor #0 received 1',
        'Processor #0 received 2',
        'Processor #1 received 3',
        'Processor #2 received 4',
        'Processor #3 received 5',
        'Processor #4 received 6',
        'Processor #0 received 7',
        'Processor #1 received 8',
        'Processor #2 received 9',
        'Processor #3 received 10',
      ]);
    }),
  );

  test(
    'fan-in',
    () => runTest((it) async {
      final log = <String>[];
      final channel = Channel<String>();
      it
        ..launch(
          (it) =>
              _sendString(channel, 'foo', const Duration(milliseconds: 200)),
        )
        ..launch(
          (it) =>
              _sendString(channel, 'BAR!', const Duration(milliseconds: 500)),
        );
      for (var index = 0; index < 6; index++) {
        log.add(await channel.receive());
      }
      it.coroutineContext.cancelChildren();

      expect(log, <String>['foo', 'foo', 'BAR!', 'foo', 'foo', 'BAR!']);
    }),
  );

  test(
    'buffered channels',
    () => runTest((it) async {
      final log = <String>[];
      final channel = Channel<int>(capacity: 4);
      final Job sender = it.launch((it) async {
        for (var index = 0; index < 10; index++) {
          log.add('Sending $index');
          await channel.send(index);
        }
      });
      await delay(const Duration(seconds: 1));
      sender.cancel();

      expect(log, <String>[
        'Sending 0',
        'Sending 1',
        'Sending 2',
        'Sending 3',
        'Sending 4',
      ]);
    }),
  );

  test(
    'channels are fair',
    () => runTest((it) async {
      final log = <String>[];
      final table = Channel<Ball>();
      it
        ..launch((it) => _player('ping', table, log))
        ..launch((it) => _player('pong', table, log));
      await table.send(Ball(0));
      await delay(const Duration(seconds: 1));
      it.coroutineContext.cancelChildren();

      expect(log, <String>[
        'ping Ball(hits=1)',
        'pong Ball(hits=2)',
        'ping Ball(hits=3)',
        'pong Ball(hits=4)',
      ]);
    }),
  );
}
