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

import 'probe_stream.dart';

/// Shorthand for a number of milliseconds.
///
/// Returns the duration.
Duration _ms(int milliseconds) => Duration(milliseconds: milliseconds);

/// Covers `debounce` and `sample` on virtual time, with the examples of
/// their Kotlin documentation.
void main() {
  group('debounce', () {
    test(
      'emits what Kotlin documents',
      () => runTest((it) async {
        Stream<int> numbers() async* {
          yield 1;
          await delay(_ms(90));
          yield 2;
          await delay(_ms(90));
          yield 3;
          await delay(_ms(1010));
          yield 4;
          await delay(_ms(1010));
          yield 5;
        }

        final log = <String>[];
        await numbers()
            .debounce(_ms(1000))
            .collect((value) => log.add('$value at ${it.currentTime}'));

        expect(log, <String>[
          '3 at ${_ms(1180)}',
          '4 at ${_ms(2190)}',
          '5 at ${_ms(2200)}',
        ]);
      }),
    );

    test('emits every element at once with a zero timeout', () async {
      final List<int> values = await Stream<int>.fromIterable(<int>[1, 2])
          .debounce(Duration.zero)
          .toList();

      expect(values, <int>[1, 2]);
    });

    test(
      'passes errors on as they arrive',
      () => runTest((it) {
        final probe = ProbeStream<int>();
        final events = <Object>[];
        final StreamSubscription<int> subscription = probe.stream
            .debounce(_ms(100))
            .listen(events.add, onError: events.add);
        addTearDown(subscription.cancel);
        it.runCurrent();

        probe.controller
          ..add(1)
          ..addError(const FormatException());
        it.runCurrent();
        final beforeTimeout = List<Object>.of(events);
        it.advanceTimeBy(_ms(100));

        expect(beforeTimeout, <Object>[isFormatException]);
        expect(events, <Object>[isFormatException, 1]);
      }),
    );

    test(
      'passes pause and resume on and calls the timer off on cancel',
      () => runTest((it) async {
        final probe = ProbeStream<int>();
        final values = <int>[];
        final StreamSubscription<int> subscription = probe.stream
            .debounce(_ms(100))
            .listen(values.add);
        it.runCurrent();
        subscription.pause();
        it.runCurrent();
        subscription.resume();
        it.runCurrent();

        probe.controller.add(1);
        it.runCurrent();
        await subscription.cancel();
        it.advanceTimeBy(_ms(200));

        expect(values, isEmpty);
        expect(probe.log, <String>['listen', 'pause', 'resume', 'cancel']);
      }),
    );

    test('refuses a negative timeout', () {
      expect(
        () => const Stream<int>.empty().debounce(_ms(-1)),
        throwsArgumentError,
      );
    });

    test('keeps a broadcast stream broadcast', () {
      final probe = ProbeStream<int>.broadcast();

      expect(probe.stream.debounce(_ms(1)).isBroadcast, isTrue);
    });
  });

  group('sample', () {
    test(
      'emits what Kotlin documents',
      () => runTest((it) async {
        Stream<int> numbers() async* {
          for (var value = 0; value < 10; value++) {
            yield value;
            await delay(_ms(110));
          }
        }

        final List<int> values = await numbers().sample(_ms(200)).toList();

        expect(values, <int>[1, 3, 5, 7, 9]);
      }),
    );

    test(
      'waits for the next period while the listener is paused',
      () => runTest((it) {
        final probe = ProbeStream<int>();
        final values = <int>[];
        final StreamSubscription<int> subscription = probe.stream
            .sample(_ms(100))
            .listen(values.add);
        addTearDown(subscription.cancel);
        it.runCurrent();

        probe.controller.add(1);
        subscription.pause();
        it.advanceTimeBy(_ms(150));
        subscription.resume();
        it.runCurrent();
        final afterResume = List<int>.of(values);
        it.advanceTimeBy(_ms(50));

        expect(afterResume, isEmpty);
        expect(values, <int>[1]);
      }),
    );

    test(
      'passes errors on as they arrive',
      () => runTest((it) async {
        final probe = ProbeStream<int>();
        final Future<void> checked = expectLater(
          probe.stream.sample(_ms(100)),
          emitsInOrder(<Object>[emitsError(isFormatException), emitsDone]),
        );

        probe.controller.addError(const FormatException());
        await probe.emitAll(<int>[]);

        await checked;
      }),
    );

    test(
      'calls the ticker off on cancel',
      () => runTest((it) async {
        final probe = ProbeStream<int>();
        final StreamSubscription<int> subscription = probe.stream
            .sample(_ms(100))
            .listen(null);
        it.runCurrent();

        await subscription.cancel();

        expect(it.testScheduler.pendingTasks, 0);
        expect(probe.log, <String>['listen', 'cancel']);
      }),
    );

    test('refuses a period that is not positive', () {
      expect(
        () => const Stream<int>.empty().sample(Duration.zero),
        throwsArgumentError,
      );
    });
  });
}
