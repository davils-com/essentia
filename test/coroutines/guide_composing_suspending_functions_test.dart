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

import 'arithmetic_exception.dart';

/// Pretends to do something useful for a second.
///
/// Returns 13.
Future<int> _doSomethingUsefulOne() async {
  await delay(1.seconds);
  return 13;
}

/// Pretends to do something useful for a second, too.
///
/// Returns 29.
Future<int> _doSomethingUsefulTwo() async {
  await delay(1.seconds);
  return 29;
}

/// Sums both useful things concurrently in a scope of its own.
///
/// Returns the sum.
Future<int> _concurrentSum() => coroutineScope((it) async {
  final Deferred<int> one = it.async((it) => _doSomethingUsefulOne());
  final Deferred<int> two = it.async((it) => _doSomethingUsefulTwo());
  return await one + await two;
});

/// Sums two values of which the second fails, logging into [log].
///
/// Returns the sum, never.
Future<int> _failedConcurrentSum(List<String> log) =>
    coroutineScope((it) async {
      final Deferred<int> one = it.async((it) async {
        try {
          await delay(const Duration(days: 365));
          return 42;
        } finally {
          log.add('First child was cancelled');
        }
      });
      final Deferred<int> two = it.async<int>((it) {
        log.add('Second child throws an exception');
        throw ArithmeticException();
      });
      return await one + await two;
    });

/// Covers the examples of the kotlinx.coroutines guide "Composing
/// suspending functions", ported line by line, with the output they print
/// and the virtual time they take as a golden log.
void main() {
  test(
    'sequential by default',
    () => runTest((it) async {
      final log = <String>[];
      final TimeMark start = it.testTimeSource.markNow();
      final int one = await _doSomethingUsefulOne();
      final int two = await _doSomethingUsefulTwo();
      log
        ..add('The answer is ${one + two}')
        ..add('Completed in ${start.elapsedNow().inMilliseconds} ms');

      expect(log, <String>['The answer is 42', 'Completed in 2000 ms']);
    }),
  );

  test(
    'concurrent using async',
    () => runTest((it) async {
      final log = <String>[];
      final TimeMark start = it.testTimeSource.markNow();
      final Deferred<int> one = it.async((it) => _doSomethingUsefulOne());
      final Deferred<int> two = it.async((it) => _doSomethingUsefulTwo());
      log
        ..add('The answer is ${await one + await two}')
        ..add('Completed in ${start.elapsedNow().inMilliseconds} ms');

      expect(log, <String>['The answer is 42', 'Completed in 1000 ms']);
    }),
  );

  test(
    'lazily started async',
    () => runTest((it) async {
      final log = <String>[];
      final TimeMark start = it.testTimeSource.markNow();
      final Deferred<int> one = it.async(
        (it) => _doSomethingUsefulOne(),
        start: CoroutineStart.lazy,
      );
      final Deferred<int> two = it.async(
        (it) => _doSomethingUsefulTwo(),
        start: CoroutineStart.lazy,
      );
      one.start();
      two.start();
      log
        ..add('The answer is ${await one + await two}')
        ..add('Completed in ${start.elapsedNow().inMilliseconds} ms');

      expect(log, <String>['The answer is 42', 'Completed in 1000 ms']);
    }),
  );

  test(
    'lazily started async awaited one after another',
    () => runTest((it) async {
      final TimeMark start = it.testTimeSource.markNow();
      final Deferred<int> one = it.async(
        (it) => _doSomethingUsefulOne(),
        start: CoroutineStart.lazy,
      );
      final Deferred<int> two = it.async(
        (it) => _doSomethingUsefulTwo(),
        start: CoroutineStart.lazy,
      );

      expect(await one + await two, 42);
      expect(start.elapsedNow(), 2.seconds);
    }),
  );

  test(
    'structured concurrency with async',
    () => runTest((it) async {
      final log = <String>[];
      final TimeMark start = it.testTimeSource.markNow();
      log
        ..add('The answer is ${await _concurrentSum()}')
        ..add('Completed in ${start.elapsedNow().inMilliseconds} ms');

      expect(log, <String>['The answer is 42', 'Completed in 1000 ms']);
    }),
  );

  test(
    'cancellation is always propagated through coroutines hierarchy',
    () => runTest((it) async {
      final log = <String>[];
      try {
        await _failedConcurrentSum(log);
      } on ArithmeticException {
        log.add('Computation failed with ArithmeticException');
      }

      expect(log, <String>[
        'Second child throws an exception',
        'First child was cancelled',
        'Computation failed with ArithmeticException',
      ]);
    }),
  );
}
