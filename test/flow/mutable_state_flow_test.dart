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

import 'guide_counter_model.dart';

/// Covers `MutableStateFlow`: the current value, conflation, equality,
/// compare-and-set, the update extensions and the read-only view.
void main() {
  group('kotlin documentation', () {
    test(
      'sums two counters with combine',
      () => runTest((it) {
        final a = GuideCounterModel();
        final b = GuideCounterModel();
        final Stream<int> sumFlow = a.counter.combine(
          b.counter,
          (a, b) => a + b,
        );
        final sums = <int>[];
        it.backgroundScope.launch((_) => sumFlow.collect(sums.add));
        it.runCurrent();

        a.inc();
        it.runCurrent();
        b.inc();
        it.runCurrent();
        a.inc();
        it.runCurrent();

        expect(sums, <int>[0, 1, 2, 3]);
        expect(a.counter.value, 2);
      }),
    );
  });

  group('value', () {
    test('starts with the value it was created with', () {
      final flow = MutableStateFlow<String?>(null);

      expect(flow.value, isNull);
      expect(flow.replayCache, <String?>[null]);
      expect(flow.toString(), 'MutableStateFlow(null)');
    });

    test('changes the value without waiting', () {
      final MutableStateFlow<int> flow = MutableStateFlow(1)..value = 2;

      expect(flow.value, 2);
      expect(flow.tryEmit(3), isTrue);
      expect(flow.value, 3);
    });

    test('changes the value through emit', () async {
      final MutableStateFlow<int> flow = MutableStateFlow(1);

      await flow.emit(2);

      expect(flow.value, 2);
    });

    test('refuses to reset its replay cache', () {
      final MutableStateFlow<int> flow = MutableStateFlow(1);

      expect(flow.resetReplayCache, throwsUnsupportedError);
    });
  });

  group('compareAndSet', () {
    test('sets the value when the current one matches', () {
      final MutableStateFlow<int> flow = MutableStateFlow(1);

      expect(flow.compareAndSet(1, 2), isTrue);
      expect(flow.value, 2);
    });

    test('leaves the value when the current one differs', () {
      final MutableStateFlow<int> flow = MutableStateFlow(1);

      expect(flow.compareAndSet(3, 2), isFalse);
      expect(flow.value, 1);
    });

    test('succeeds without a change when the update is the value', () {
      final MutableStateFlow<int> flow = MutableStateFlow(1);

      expect(flow.compareAndSet(1, 1), isTrue);
    });
  });

  group('update', () {
    test('updates the value and reports the new one', () {
      final MutableStateFlow<int> flow = MutableStateFlow(1);

      expect(flow.updateAndGet((value) => value + 1), 2);
      expect(flow.value, 2);
    });

    test('updates the value and reports the previous one', () {
      final MutableStateFlow<int> flow = MutableStateFlow(1);

      expect(flow.getAndUpdate((value) => value + 1), 1);
      expect(flow.value, 2);
    });

    test('runs the function again when the value changed meanwhile', () {
      final MutableStateFlow<int> flow = MutableStateFlow(1);
      var runs = 0;

      int add(int value) {
        runs++;
        if (runs == 1) {
          flow.value = 10;
        }
        return value + 1;
      }

      flow.update(add);
      final int previous = flow.getAndUpdate((value) {
        if (value == 11) {
          flow.value = 20;
        }
        return value + 1;
      });

      expect(runs, 2);
      expect(previous, 20);
      expect(flow.value, 21);
    });
  });

  group('listening', () {
    test(
      'gives a new listener the current value first',
      () => runTest((it) {
        final MutableStateFlow<int> flow = MutableStateFlow(1);
        final values = <int>[];

        it.backgroundScope.launch((_) => flow.collect(values.add));
        it.runCurrent();
        flow.value = 2;
        it.runCurrent();

        expect(values, <int>[1, 2]);
      }),
    );

    test(
      'conflates the values a busy listener missed',
      () => runTest((it) {
        final MutableStateFlow<int> flow = MutableStateFlow(0);
        final values = <int>[];
        it.backgroundScope.launch(
          (_) => flow.collect((value) async {
            values.add(value);
            await delay(const Duration(milliseconds: 100));
          }),
        );
        it.runCurrent();

        for (var value = 1; value <= 5; value++) {
          flow.value = value;
          it.advanceTimeBy(const Duration(milliseconds: 30));
        }
        it.advanceTimeBy(const Duration(milliseconds: 200));

        expect(values, <int>[0, 4, 5]);
      }),
    );

    test(
      'skips a value equal to the one delivered last',
      () => runTest((it) {
        final MutableStateFlow<int> flow = MutableStateFlow(0);
        final values = <int>[];
        it.backgroundScope.launch((_) => flow.collect(values.add));
        it.runCurrent();

        flow
          ..value = 1
          ..value = 0;
        it.runCurrent();
        flow.value = 0;
        it.runCurrent();

        expect(values, <int>[0]);
      }),
    );

    test(
      'counts its listeners',
      () => runTest((it) async {
        final MutableStateFlow<int> flow = MutableStateFlow(0);
        final StateFlow<int> count = flow.subscriptionCount;

        final Job collecting = it.launch((_) => flow.collect());
        it.runCurrent();
        final int during = count.value;
        await collecting.cancelAndJoin();

        expect(during, 1);
        expect(count.value, 0);
      }),
    );

    test(
      'ends a collector with the cancellation of its job',
      () => runTest((it) async {
        final MutableStateFlow<int> flow = MutableStateFlow(0);
        final Job collecting = it.launch((_) => flow.collect());
        it.runCurrent();

        await collecting.cancelAndJoin();

        expect(collecting.isCancelled, isTrue);
        expect(flow.subscriptionCount.value, 0);
      }),
    );

    test('holds the value back from a paused listener', () async {
      final MutableStateFlow<int> flow = MutableStateFlow(0);
      final values = <int>[];
      final StreamSubscription<int> subscription = flow.listen(values.add);
      addTearDown(subscription.cancel);
      await Future<void>.delayed(Duration.zero);

      subscription.pause();
      flow
        ..value = 1
        ..value = 2;
      await Future<void>.delayed(Duration.zero);
      final whilePaused = List<int>.of(values);
      subscription.resume();
      await Future<void>.delayed(Duration.zero);

      expect(whilePaused, <int>[0]);
      expect(values, <int>[0, 2]);
    });
  });

  group('views', () {
    test('hides the mutable flow behind the read-only state view', () {
      final MutableStateFlow<int> flow = MutableStateFlow(1);

      final StateFlow<int> view = flow.asStateFlow();
      flow.value = 2;

      expect(view, isNot(isA<MutableStateFlow<int>>()));
      expect(view.value, 2);
      expect(view.replayCache, <int>[2]);
      expect(view.isBroadcast, isTrue);
      expect(view.toString(), 'MutableStateFlow(2)');
    });

    test('offers a read-only shared view as well', () async {
      final MutableStateFlow<int> flow = MutableStateFlow(1);

      final SharedFlow<int> view = flow.asSharedFlow();

      expect(view, isNot(isA<StateFlow<int>>()));
      expect(view.replayCache, <int>[1]);
      expect(await view.first, 1);
    });

    test('is a broadcast stream', () {
      expect(MutableStateFlow(0).isBroadcast, isTrue);
    });
  });
}
