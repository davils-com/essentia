/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_coroutines/testing.dart';
import 'package:test/test.dart';

/// Sends [text] every [period].
///
/// Returns the channel of texts.
ReceiveChannel<String> _every(
  CoroutineScope scope,
  String text,
  Duration period,
) => scope.produce((it) async {
  while (true) {
    await delay(period);
    await it.send(text);
  }
});

/// Receives from [a] or [b], telling which one is closed.
///
/// Returns what was received.
Future<String> _selectAorB(
  ReceiveChannel<String> a,
  ReceiveChannel<String> b,
) => select<String>((it) {
  it
    ..onReceiveCatching(a, (result) {
      final String? value = result.getOrNull();
      return value == null ? "Channel 'a' is closed" : "a -> '$value'";
    })
    ..onReceiveCatching(b, (result) {
      final String? value = result.getOrNull();
      return value == null ? "Channel 'b' is closed" : "b -> '$value'";
    });
});

/// Waits [time], then answers [text].
///
/// Returns the deferred answer.
Deferred<String> _asyncString(CoroutineScope scope, String text, int time) =>
    scope.async((it) async {
      await delay(Duration(milliseconds: time));
      return text;
    });

/// Sends the value of the newest deferred of [input], dropping a deferred once
/// a newer one arrives.
///
/// Returns the channel of values.
ReceiveChannel<String> _switchMapDeferreds(
  CoroutineScope scope,
  ReceiveChannel<Deferred<String>> input,
  List<String> log,
) => scope.produce((it) async {
  Deferred<String> current = await input.receive();
  while (it.isActive) {
    final Deferred<String>? next = await select<Deferred<String>?>((select) {
      select
        ..onReceiveCatching(input, (update) => update.getOrNull())
        ..onAwait(current, (value) async {
          await it.send(value);
          return (await input.receiveCatching()).getOrNull();
        });
    });
    if (next == null) {
      log.add('Channel was closed');
      break;
    }
    current = next;
  }
});

/// Covers the worked examples of select expressions; each asserts the whole
/// output of its example.
///
/// "Selecting on close" lets the producers run between two selects: how many
/// microtasks a producer needs to close its channel after its last send differs
/// between the VM, JavaScript and WebAssembly. The select is biased, so `a`
/// wins while it has elements and its closure wins afterwards.
void main() {
  test(
    'selecting from channels',
    () => runTest((it) async {
      final log = <String>[];
      final ReceiveChannel<String> fizz = _every(
        it,
        'Fizz',
        const Duration(milliseconds: 500),
      );
      final ReceiveChannel<String> buzz = _every(
        it,
        'Buzz!',
        const Duration(milliseconds: 1000),
      );
      for (var round = 0; round < 7; round++) {
        await select<void>((it) {
          it
            ..onReceive(fizz, (value) => log.add("fizz -> '$value'"))
            ..onReceive(buzz, (value) => log.add("buzz -> '$value'"));
        });
      }
      it.coroutineContext.cancelChildren();

      expect(log, <String>[
        "fizz -> 'Fizz'",
        "buzz -> 'Buzz!'",
        "fizz -> 'Fizz'",
        "fizz -> 'Fizz'",
        "buzz -> 'Buzz!'",
        "fizz -> 'Fizz'",
        "fizz -> 'Fizz'",
      ]);
    }),
  );

  test(
    'selecting on close',
    () => runTest((it) async {
      final log = <String>[];
      final ReceiveChannel<String> a = it.produce((it) async {
        for (var index = 0; index < 4; index++) {
          await it.send('Hello $index');
        }
      });
      final ReceiveChannel<String> b = it.produce((it) async {
        for (var index = 0; index < 4; index++) {
          await it.send('World $index');
        }
      });
      await yieldNow();
      for (var round = 0; round < 8; round++) {
        log.add(await _selectAorB(a, b));
        await yieldNow();
      }
      it.coroutineContext.cancelChildren();

      expect(log, <String>[
        "a -> 'Hello 0'",
        "a -> 'Hello 1'",
        "a -> 'Hello 2'",
        "a -> 'Hello 3'",
        "Channel 'a' is closed",
        "Channel 'a' is closed",
        "Channel 'a' is closed",
        "Channel 'a' is closed",
      ]);
    }),
  );

  test(
    'selecting to send',
    () => runTest((it) async {
      final log = <String>[];
      final side = Channel<int>();
      it.launch(
        (it) => side.consumeEach((value) => log.add('Side channel has $value')),
      );
      final ReceiveChannel<int> numbers = it.produce((it) async {
        for (var number = 1; number <= 10; number++) {
          await delay(const Duration(milliseconds: 100));
          await select<void>((select) {
            select
              ..onSend(it, number, (channel) {})
              ..onSend(side, number, (channel) {});
          });
        }
      });
      await numbers.consumeEach((value) async {
        log.add('Consuming $value');
        await delay(const Duration(milliseconds: 250));
      });
      log.add('Done consuming');
      it.coroutineContext.cancelChildren();

      expect(log, <String>[
        'Consuming 1',
        'Side channel has 2',
        'Side channel has 3',
        'Consuming 4',
        'Side channel has 5',
        'Side channel has 6',
        'Consuming 7',
        'Side channel has 8',
        'Side channel has 9',
        'Consuming 10',
        'Done consuming',
      ]);
    }),
  );

  test(
    'selecting deferred values',
    () => runTest((it) async {
      final log = <String>[];
      final random = Random(3);
      final list = <Deferred<String>>[];
      for (var index = 0; index < 12; index++) {
        final int time = random.nextInt(1000);
        list.add(_asyncString(it, 'Waited for $time ms', time));
      }
      final String result = await select<String>((it) {
        for (var index = 0; index < list.length; index++) {
          it.onAwait(
            list[index],
            (answer) => "Deferred $index produced answer '$answer'",
          );
        }
      });
      log
        ..add(result)
        ..add(
          '${list.where((deferred) => deferred.isActive).length} '
          'coroutines are still active',
        );
      it.coroutineContext.cancelChildren();

      expect(log, <String>[
        "Deferred 7 produced answer 'Waited for 8 ms'",
        '11 coroutines are still active',
      ]);
    }),
  );

  test(
    'switch over a channel of deferred values',
    () => runTest((it) async {
      final log = <String>[];
      final channel = Channel<Deferred<String>>();
      it.launch((it) async {
        final ReceiveChannel<String> values = _switchMapDeferreds(
          it,
          channel,
          log,
        );
        await values.receiveAsStream().forEach(log.add);
      });
      await channel.send(_asyncString(it, 'BEGIN', 100));
      await delay(const Duration(milliseconds: 200));
      await channel.send(_asyncString(it, 'Slow', 500));
      await delay(const Duration(milliseconds: 100));
      await channel.send(_asyncString(it, 'Replace', 100));
      await delay(const Duration(milliseconds: 500));
      await channel.send(_asyncString(it, 'END', 500));
      await delay(const Duration(milliseconds: 1000));
      channel.close();
      await delay(const Duration(milliseconds: 500));

      expect(log, <String>['BEGIN', 'Replace', 'END', 'Channel was closed']);
    }),
  );
}
