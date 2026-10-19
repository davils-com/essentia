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

import 'guide_event_bus.dart';

/// Lets every pending microtask and zero delay timer run.
///
/// Returns a future that completes after them.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

/// Covers `MutableSharedFlow`: replay, buffering, overflow, backpressure,
/// subscription counting, re-entrancy and cancellation of listeners.
void main() {
  group('validation', () {
    test('refuses a negative replay', () {
      expect(
        () => MutableSharedFlow<int>(replay: -1),
        throwsA(
          isArgumentError.having(
            (error) => error.message,
            'message',
            'replay cannot be negative, but was -1',
          ),
        ),
      );
    });

    test('refuses a negative extra buffer capacity', () {
      expect(
        () => MutableSharedFlow<int>(extraBufferCapacity: -2),
        throwsA(
          isArgumentError.having(
            (error) => error.message,
            'message',
            'extraBufferCapacity cannot be negative, but was -2',
          ),
        ),
      );
    });

    test('refuses a dropping policy without a buffer', () {
      expect(
        () =>
            MutableSharedFlow<int>(onBufferOverflow: BufferOverflow.dropOldest),
        throwsA(
          isArgumentError.having(
            (error) => error.message,
            'message',
            'replay or extraBufferCapacity must be positive with non-default '
                'onBufferOverflow strategy BufferOverflow.dropOldest',
          ),
        ),
      );
    });
  });

  group('event bus', () {
    test(
      'delivers the events of an event bus to every subscriber',
      () => runTest((it) async {
        final bus = GuideEventBus();
        final first = <String>[];
        final second = <String>[];
        it.backgroundScope
          ..launch((_) => bus.events.collect(first.add))
          ..launch((_) => bus.events.collect(second.add));
        it.runCurrent();

        await bus.produceEvent('a');
        await bus.produceEvent('b');
        it.runCurrent();

        expect(first, <String>['a', 'b']);
        expect(second, <String>['a', 'b']);
      }),
    );
  });

  group('replay', () {
    test(
      'drops values nobody listens to without a replay',
      () => runTest((it) async {
        final flow = MutableSharedFlow<int>();

        expect(flow.tryEmit(1), isTrue);
        await flow.emit(2);

        expect(flow.replayCache, isEmpty);
      }),
    );

    test(
      'keeps the last replay values for a new listener',
      () => runTest((it) async {
        final flow = MutableSharedFlow<int>(replay: 2);
        await flow.emit(1);
        await flow.emit(2);
        await flow.emit(3);
        final values = <int>[];

        it.backgroundScope.launch((_) => flow.collect(values.add));
        it.runCurrent();

        expect(flow.replayCache, <int>[2, 3]);
        expect(values, <int>[2, 3]);
      }),
    );

    test(
      'forgets the replay values on reset',
      () => runTest((it) async {
        final flow = MutableSharedFlow<int>(replay: 2);
        await flow.emit(1);

        flow.resetReplayCache();
        final values = <int>[];
        it.backgroundScope.launch((_) => flow.collect(values.add));
        it.runCurrent();
        await flow.emit(2);
        it.runCurrent();

        expect(flow.replayCache, <int>[2]);
        expect(values, <int>[2]);
      }),
    );

    test(
      'still delivers values a listener has not taken on reset',
      () => runTest((it) async {
        final flow = MutableSharedFlow<int>(replay: 1, extraBufferCapacity: 2);
        final values = <int>[];
        final gate = Completer<void>();
        it.backgroundScope.launch(
          (_) => flow.collect((value) async {
            values.add(value);
            await gate.future;
          }),
        );
        it.runCurrent();
        await flow.emit(1);
        await flow.emit(2);
        await flow.emit(3);
        it.runCurrent();

        flow.resetReplayCache();
        gate.complete();
        it.runCurrent();

        expect(flow.replayCache, isEmpty);
        expect(values, <int>[1, 2, 3]);
      }),
    );

    test('returns an unmodifiable snapshot of the replay cache', () {
      final flow = MutableSharedFlow<int>(replay: 1)..tryEmit(1);

      expect(() => flow.replayCache.add(2), throwsUnsupportedError);
    });
  });

  group('backpressure', () {
    test(
      'makes the emitter wait for a slow collector',
      () => runTest((it) async {
        final flow = MutableSharedFlow<int>();
        final log = <String>[];
        it.backgroundScope.launch(
          (_) => flow.collect((value) async {
            log.add('collect $value at ${it.currentTime.inMilliseconds}');
            await delay(const Duration(milliseconds: 100));
          }),
        );
        it.runCurrent();

        for (var value = 1; value <= 3; value++) {
          await flow.emit(value);
          log.add('emitted $value at ${it.currentTime.inMilliseconds}');
        }

        expect(log, <String>[
          'collect 1 at 0',
          'emitted 1 at 0',
          'collect 2 at 100',
          'emitted 2 at 100',
          'collect 3 at 200',
          'emitted 3 at 200',
        ]);
      }),
    );

    test(
      'lets the emitter run ahead by the buffer',
      () => runTest((it) async {
        final flow = MutableSharedFlow<int>(extraBufferCapacity: 2);
        final emitted = <int>[];
        final gate = Completer<void>();
        it.backgroundScope.launch((_) => flow.collect((value) => gate.future));
        it.runCurrent();

        final Job emitting = it.launch((_) async {
          for (var value = 1; value <= 4; value++) {
            await flow.emit(value);
            emitted.add(value);
          }
        });
        it.runCurrent();
        final ahead = List<int>.of(emitted);
        gate.complete();
        await emitting.join();

        expect(ahead, <int>[1, 2, 3]);
        expect(emitted, <int>[1, 2, 3, 4]);
      }),
    );

    test(
      'refuses to emit without waiting when the buffer is full',
      () => runTest((it) {
        final flow = MutableSharedFlow<int>(extraBufferCapacity: 1);
        final gate = Completer<void>();
        it.backgroundScope.launch((_) => flow.collect((value) => gate.future));
        it.runCurrent();

        final bool first = flow.tryEmit(1);
        it.runCurrent();
        final bool second = flow.tryEmit(2);
        final bool third = flow.tryEmit(3);
        gate.complete();

        expect((first, second, third), (true, true, false));
      }),
    );

    test(
      'drops the oldest value for a lagging collector',
      () => runTest((it) {
        final flow = MutableSharedFlow<int>(
          extraBufferCapacity: 2,
          onBufferOverflow: BufferOverflow.dropOldest,
        );
        final values = <int>[];
        final gate = Completer<void>();
        it.backgroundScope.launch(
          (_) => flow.collect((value) async {
            values.add(value);
            await gate.future;
          }),
        );
        it.runCurrent();

        for (var value = 1; value <= 5; value++) {
          expect(flow.tryEmit(value), isTrue);
          it.runCurrent();
        }
        gate.complete();
        it.runCurrent();

        expect(values, <int>[1, 4, 5]);
      }),
    );

    test(
      'drops the newest value for a lagging collector',
      () => runTest((it) {
        final flow = MutableSharedFlow<int>(
          extraBufferCapacity: 2,
          onBufferOverflow: BufferOverflow.dropLatest,
        );
        final values = <int>[];
        final gate = Completer<void>();
        it.backgroundScope.launch(
          (_) => flow.collect((value) async {
            values.add(value);
            await gate.future;
          }),
        );
        it.runCurrent();

        for (var value = 1; value <= 5; value++) {
          expect(flow.tryEmit(value), isTrue);
          it.runCurrent();
        }
        gate.complete();
        it.runCurrent();

        expect(values, <int>[1, 2, 3]);
      }),
    );

    test('keeps the replay window of a dropping flow without listeners', () {
      final flow = MutableSharedFlow<int>(
        replay: 2,
        onBufferOverflow: BufferOverflow.dropOldest,
      );

      for (var value = 1; value <= 4; value++) {
        flow.tryEmit(value);
      }

      expect(flow.replayCache, <int>[3, 4]);
    });

    test(
      'resumes every waiting emitter once the last listener left',
      () => runTest((it) async {
        final flow = MutableSharedFlow<int>(replay: 1);
        final Job collecting = it.launch(
          (_) => flow.collect((value) => awaitCancellation()),
        );
        it.runCurrent();
        await flow.emit(1);
        it.runCurrent();
        await flow.emit(2);
        var done = 0;
        for (var value = 3; value <= 4; value++) {
          unawaited(flow.emit(value).then((_) => done++));
        }
        it.runCurrent();
        final waitingBefore = done;

        await collecting.cancelAndJoin();
        it.runCurrent();

        expect(waitingBefore, 0);
        expect(done, 2);
        expect(flow.replayCache, <int>[4]);
      }),
    );

    test(
      'stops a waiting emitter whose job is cancelled',
      () => runTest((it) async {
        final flow = MutableSharedFlow<int>();
        final values = <int>[];
        final gate = Completer<void>();
        it.backgroundScope.launch(
          (_) => flow.collect((value) async {
            values.add(value);
            await gate.future;
          }),
        );
        it.runCurrent();
        await flow.emit(1);
        it.runCurrent();

        final Job emitting = it.launch((_) => flow.emit(2));
        final Job waiting = it.launch((_) => flow.emit(3));
        it.runCurrent();
        await waiting.cancelAndJoin();
        gate.complete();
        await emitting.join();
        it.runCurrent();

        expect(waiting.isCancelled, isTrue);
        expect(values, <int>[1, 2]);
      }),
    );

    test(
      'drops a cancelled emitter from the middle of the queue',
      () => runTest((it) async {
        final flow = MutableSharedFlow<int>(extraBufferCapacity: 1);
        final values = <int>[];
        final gate = Completer<void>();
        it.backgroundScope.launch(
          (_) => flow.collect((value) async {
            values.add(value);
            await gate.future;
          }),
        );
        it.runCurrent();
        await flow.emit(1);
        it.runCurrent();
        await flow.emit(2);

        final Job second = it.launch((_) => flow.emit(3));
        final Job third = it.launch((_) => flow.emit(4));
        final Job fourth = it.launch((_) => flow.emit(5));
        it.runCurrent();
        await third.cancelAndJoin();
        await fourth.cancelAndJoin();
        gate.complete();
        await second.join();
        it.runCurrent();

        expect(values, <int>[1, 2, 3]);
      }),
    );
  });

  group('rendezvous', () {
    test(
      'hands a value over only when every collector took it',
      () => runTest((it) async {
        final flow = MutableSharedFlow<int>();
        final fast = <int>[];
        final slow = <int>[];
        final gate = Completer<void>();
        it.backgroundScope
          ..launch((_) => flow.collect(fast.add))
          ..launch(
            (_) => flow.collect((value) async {
              slow.add(value);
              await gate.future;
            }),
          );
        it.runCurrent();

        final Job emitting = it.launch((_) async {
          await flow.emit(1);
          await flow.emit(2);
          await flow.emit(3);
        });
        it.runCurrent();
        final fastBefore = List<int>.of(fast);
        gate.complete();
        await emitting.join();
        it.runCurrent();

        expect(fastBefore, <int>[1, 2]);
        expect(fast, <int>[1, 2, 3]);
        expect(slow, <int>[1, 2, 3]);
      }),
    );

    test(
      'skips a cancelled emitter at the head of the queue',
      () => runTest((it) async {
        final flow = MutableSharedFlow<int>();
        final values = <int>[];
        final gate = Completer<void>();
        it.backgroundScope.launch(
          (_) => flow.collect((value) async {
            values.add(value);
            await gate.future;
          }),
        );
        it.runCurrent();
        await flow.emit(1);
        it.runCurrent();

        final Job cancelled = it.launch((_) => flow.emit(2));
        final Job waiting = it.launch((_) => flow.emit(3));
        it.runCurrent();
        await cancelled.cancelAndJoin();
        gate.complete();
        await waiting.join();
        it.runCurrent();

        expect(values, <int>[1, 3]);
      }),
    );
  });

  group('subscriptionCount', () {
    test(
      'counts listeners as they come and go',
      () => runTest((it) async {
        final flow = MutableSharedFlow<int>();
        final counts = <int>[];
        it.backgroundScope.launch(
          (_) => flow.subscriptionCount.collect(counts.add),
        );
        it.runCurrent();

        final Job first = it.launch((_) => flow.collect());
        it.runCurrent();
        final Job second = it.launch((_) => flow.collect());
        it.runCurrent();
        await first.cancelAndJoin();
        it.runCurrent();
        await second.cancelAndJoin();
        it.runCurrent();

        expect(counts, <int>[0, 1, 2, 1, 0]);
        expect(flow.subscriptionCount.value, 0);
      }),
    );

    test('starts at the current count when asked late', () {
      final flow = MutableSharedFlow<int>();
      final StreamSubscription<int> subscription = flow.listen(null);
      addTearDown(subscription.cancel);

      expect(flow.subscriptionCount.value, 1);
    });
  });

  group('listening', () {
    test('is a broadcast stream', () {
      final flow = MutableSharedFlow<int>();

      expect(flow.isBroadcast, isTrue);
      expect(flow.asSharedFlow().isBroadcast, isTrue);
    });

    test('hides the mutable flow behind the read-only view', () {
      final flow = MutableSharedFlow<int>(replay: 1)..tryEmit(1);

      final SharedFlow<int> view = flow.asSharedFlow();

      expect(view, isNot(isA<MutableSharedFlow<int>>()));
      expect(view.replayCache, <int>[1]);
      expect(view.toString(), flow.toString());
      expect(
        flow.toString(),
        'MutableSharedFlow(replay: 1, buffered: 1, waiting emitters: 0, '
        'listeners: 0)',
      );
    });

    test('delivers to a plain listener outside every coroutine', () async {
      final flow = MutableSharedFlow<int>(extraBufferCapacity: 4);
      final values = <int>[];
      final StreamSubscription<int> subscription = flow.listen(values.add);
      addTearDown(subscription.cancel);
      await _settle();

      flow
        ..tryEmit(1)
        ..tryEmit(2);
      await _settle();

      expect(values, <int>[1, 2]);
    });

    test('holds values back from a paused listener', () async {
      final flow = MutableSharedFlow<int>(extraBufferCapacity: 4);
      final values = <int>[];
      final StreamSubscription<int> subscription = flow.listen(values.add);
      addTearDown(subscription.cancel);
      await _settle();

      subscription.pause();
      flow.tryEmit(1);
      await _settle();
      final whilePaused = List<int>.of(values);
      subscription.resume();
      await _settle();

      expect(whilePaused, isEmpty);
      expect(values, <int>[1]);
    });

    test(
      'never delivers inside emit, so a collector can emit back',
      () => runTest((it) {
        final flow = MutableSharedFlow<int>(extraBufferCapacity: 8);
        final values = <int>[];
        it.backgroundScope.launch(
          (_) => flow.collect((value) {
            values.add(value);
            if (value < 3) {
              final bool emitted = flow.tryEmit(value + 1);
              values.add(emitted ? -value : 0);
            }
          }),
        );
        it.runCurrent();

        flow.tryEmit(1);
        final duringEmit = List<int>.of(values);
        it.runCurrent();

        expect(duringEmit, isEmpty);
        expect(values, <int>[1, -1, 2, -2, 3]);
      }),
    );

    test(
      'ends a collector with the cancellation of its job',
      () => runTest((it) async {
        final flow = MutableSharedFlow<int>();
        Object? failure;
        final Job collecting = it.launch((_) async {
          try {
            await for (final _ in flow) {}
          } on CancellationException catch (error) {
            failure = error;
            rethrow;
          }
        });
        it.runCurrent();

        await collecting.cancelAndJoin();

        expect(failure, isA<CancellationException>());
        expect(collecting.isCancelled, isTrue);
        expect(flow.subscriptionCount.value, 0);
      }),
    );

    test(
      'ends a listener that subscribes inside a cancelled job',
      () => runTest((it) {
        final flow = MutableSharedFlow<int>();
        final events = <Object>[];
        final job = Job()..cancel();

        CoroutineScope(job).launch(
          start: CoroutineStart.undispatched,
          (_) => flow.listen(events.add, onError: events.add),
        );
        it.runCurrent();

        expect(events.single, isA<CancellationException>());
        expect(flow.subscriptionCount.value, 0);
      }),
    );

    test(
      'keeps a listener of a coroutine whose body returned',
      () => runTest((it) async {
        final flow = MutableSharedFlow<int>(extraBufferCapacity: 1);
        final values = <int>[];
        final StreamSubscription<int> subscription = await it.async(
          (_) => flow.listen(values.add),
        );
        addTearDown(subscription.cancel);
        it.runCurrent();

        flow.tryEmit(1);
        it.runCurrent();

        expect(values, <int>[1]);
        expect(flow.subscriptionCount.value, 1);
      }),
    );
  });
}
