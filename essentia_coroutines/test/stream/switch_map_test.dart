/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/stream/switch_map.dart';
import 'package:test/test.dart';

import 'probe_stream.dart';

/// Checks the switching that `mapLatest` and `collectLatest` build on.
void main() {
  group('ordering', () {
    test('emits the events of the latest inner stream only', () async {
      final outer = ProbeStream<int>();
      final first = ProbeStream<String>();
      final second = ProbeStream<String>();
      final inners = <int, ProbeStream<String>>{1: first, 2: second};
      final Future<List<String>> events = switchMap(
        outer.stream,
        (value) => inners[value]!.stream,
      ).toList();

      outer.controller.add(1);
      await settle();
      first.controller.add('a');
      await settle();
      outer.controller.add(2);
      await settle();
      first.controller.add('stale');
      second.controller
        ..add('b')
        ..add('c');
      await settle();
      await second.emitAll(<String>['d']);
      await outer.controller.close();

      expect(await events, <String>['a', 'b', 'c', 'd']);
    });

    test('emits an inner stream in full when it ends in time', () async {
      final outer = ProbeStream<int>();
      final Future<List<int>> events = switchMap(
        outer.stream,
        (value) => Stream<int>.fromIterable(<int>[value, value * 10]),
      ).toList();

      outer.controller.add(1);
      await settle();
      await outer.emitAll(<int>[2]);

      expect(await events, <int>[1, 10, 2, 20]);
    });

    test('drops the rest of an inner stream on the next element', () async {
      final outer = ProbeStream<int>();
      final first = ProbeStream<int>();
      final Future<List<int>> events = switchMap(
        outer.stream,
        (value) => value == 1 ? first.stream : Stream<int>.value(value),
      ).toList();

      outer.controller.add(1);
      await settle();
      first.controller.add(10);
      await settle();
      await outer.emitAll(<int>[2]);
      first.controller.add(11);

      expect(await events, <int>[10, 2]);
    });
  });

  group('cancellation', () {
    test('cancels the previous inner stream on the next element', () async {
      final outer = ProbeStream<int>();
      final first = ProbeStream<String>();
      final second = ProbeStream<String>();
      final inners = <int, ProbeStream<String>>{1: first, 2: second};
      final StreamSubscription<String> subscription = switchMap(
        outer.stream,
        (value) => inners[value]!.stream,
      ).listen(null);

      outer.controller.add(1);
      await settle();
      outer.controller.add(2);
      await settle();
      await subscription.cancel();

      expect(first.log, <String>['listen', 'cancel']);
      expect(second.log, <String>['listen', 'cancel']);
      expect(outer.log, <String>['listen', 'pause', 'resume', 'cancel']);
    });

    test('cancels the source and the inner stream on cancel', () async {
      final outer = ProbeStream<int>();
      final inner = ProbeStream<String>();
      final StreamSubscription<String> subscription = switchMap(
        outer.stream,
        (_) => inner.stream,
      ).listen(null);

      outer.controller.add(1);
      await settle();
      await subscription.cancel();

      expect(outer.log, <String>['listen', 'cancel']);
      expect(inner.log, <String>['listen', 'cancel']);
    });

    test(
      'waits for the previous cancel before listening to the next',
      () async {
        final cancelled = Completer<void>();
        final outer = ProbeStream<int>();
        final first = ProbeStream<String>(onCancel: () => cancelled.future);
        final second = ProbeStream<String>();
        final inners = <int, ProbeStream<String>>{1: first, 2: second};
        final StreamSubscription<String> subscription = switchMap(
          outer.stream,
          (value) => inners[value]!.stream,
        ).listen(null);

        outer.controller.add(1);
        await settle();
        outer.controller.add(2);
        await settle();
        final whileCancelling = List<String>.of(second.log);
        cancelled.complete();
        await settle();
        await subscription.cancel();

        expect(whileCancelling, isEmpty);
        expect(second.log, <String>['listen', 'cancel']);
      },
    );

    test('cancels the latest inner stream when the listener left while '
        'switching', () async {
      final cancelled = Completer<void>();
      final outer = ProbeStream<int>();
      final first = ProbeStream<String>(onCancel: () => cancelled.future);
      final second = ProbeStream<String>();
      final inners = <int, ProbeStream<String>>{1: first, 2: second};
      final StreamSubscription<String> subscription = switchMap(
        outer.stream,
        (value) => inners[value]!.stream,
      ).listen(null);

      outer.controller.add(1);
      await settle();
      outer.controller.add(2);
      await settle();
      final Future<void> leaving = subscription.cancel();
      cancelled.complete();
      await leaving;
      await settle();

      expect(second.log, <String>['listen', 'cancel']);
    });
  });

  group('completion', () {
    test('ends only once the source and the inner stream ended', () async {
      final outer = ProbeStream<int>();
      final inner = ProbeStream<String>();
      var done = false;
      final Future<void> drained = switchMap(
        outer.stream,
        (_) => inner.stream,
      ).drain<void>().then((_) => done = true);

      await outer.emitAll(<int>[1]);
      await settle();
      final doneEarly = done;
      await inner.emitAll(<String>[]);
      await drained;

      expect((doneEarly, done), (false, true));
    });

    test('ends once the source ends while no inner stream runs', () async {
      final Stream<String> switched = switchMap(
        const Stream<int>.empty(),
        (_) => const Stream<String>.empty(),
      );

      await expectLater(switched, emitsDone);
    });

    test('ends after an inner stream that ended before the source', () async {
      final outer = ProbeStream<int>();
      final Future<List<int>> events = switchMap(
        outer.stream,
        Stream<int>.value,
      ).toList();

      outer.controller.add(1);
      await settle();
      await outer.controller.close();

      expect(await events, <int>[1]);
    });
  });

  group('errors', () {
    test('passes errors of the source on and keeps going', () async {
      final outer = ProbeStream<int>();
      final Stream<int> switched = switchMap(outer.stream, Stream<int>.value);
      final Future<void> checked = expectLater(
        switched,
        emitsInOrder(<Object>[emitsError(isFormatException), 1, emitsDone]),
      );

      outer.controller.addError(const FormatException());
      await outer.emitAll(<int>[1]);

      await checked;
    });

    test('passes errors of an inner stream on and keeps going', () async {
      final Stream<int> switched = switchMap(
        Stream<int>.fromIterable(<int>[1, 2]),
        (value) => value == 1
            ? Stream<int>.error(const FormatException())
            : Stream<int>.value(value),
      );

      await expectLater(
        switched,
        emitsInOrder(<Object>[emitsError(isFormatException), 2, emitsDone]),
      );
    });

    test('passes an error of the conversion on and keeps going', () async {
      final Stream<int> switched = switchMap(
        Stream<int>.fromIterable(<int>[1, 2]),
        (value) => value == 1
            ? throw const FormatException()
            : Stream<int>.value(value),
      );

      await expectLater(
        switched,
        emitsInOrder(<Object>[emitsError(isFormatException), 2, emitsDone]),
      );
    });

    test(
      'passes an error of cancelling the previous inner stream on',
      () async {
        final outer = ProbeStream<int>();
        final first = ProbeStream<String>(
          onCancel: () => Future<void>.error(const FormatException()),
        );
        final inners = <int, Stream<String>>{
          1: first.stream,
          2: Stream<String>.value('b'),
        };
        final Stream<String> switched = switchMap(
          outer.stream,
          (value) => inners[value]!,
        );
        final Future<void> checked = expectLater(
          switched,
          emitsInOrder(<Object>[emitsError(isFormatException), 'b', emitsDone]),
        );

        outer.controller.add(1);
        await settle();
        await outer.emitAll(<int>[2]);

        await checked;
      },
    );
  });

  group('pause and resume', () {
    test('reach the source and the current inner stream', () async {
      final outer = ProbeStream<int>();
      final inner = ProbeStream<String>();
      final StreamSubscription<String> subscription = switchMap(
        outer.stream,
        (_) => inner.stream,
      ).listen(null);
      outer.controller.add(1);
      await settle();

      subscription.pause();
      await settle();
      subscription.resume();
      await settle();
      await subscription.cancel();

      const lifecycle = <String>['listen', 'pause', 'resume', 'cancel'];
      expect(outer.log, lifecycle);
      expect(inner.log, lifecycle);
    });

    test('hold back the events of the inner stream', () async {
      final outer = ProbeStream<int>();
      final inner = ProbeStream<String>();
      final events = <String>[];
      final StreamSubscription<String> subscription = switchMap(
        outer.stream,
        (_) => inner.stream,
      ).listen(events.add);
      outer.controller.add(1);
      await settle();

      subscription.pause();
      inner.controller.add('a');
      await settle();
      final whilePaused = List<String>.of(events);
      subscription.resume();
      await settle();
      await subscription.cancel();

      expect(whilePaused, isEmpty);
      expect(events, <String>['a']);
    });

    test('pause an inner stream that starts while paused', () async {
      final cancelled = Completer<void>();
      final outer = ProbeStream<int>();
      final first = ProbeStream<String>(onCancel: () => cancelled.future);
      final second = ProbeStream<String>();
      final inners = <int, ProbeStream<String>>{1: first, 2: second};
      final StreamSubscription<String> subscription = switchMap(
        outer.stream,
        (value) => inners[value]!.stream,
      ).listen(null);
      outer.controller.add(1);
      await settle();
      outer.controller.add(2);
      await settle();

      subscription.pause();
      cancelled.complete();
      await settle();
      final whilePaused = List<String>.of(second.log);
      subscription.resume();
      await settle();
      await subscription.cancel();

      expect(whilePaused, <String>['listen', 'pause']);
      expect(second.log, <String>['listen', 'pause', 'resume', 'cancel']);
    });
  });

  group('broadcast', () {
    test('keeps a single subscription source single subscription', () {
      final outer = ProbeStream<int>();

      final Stream<int> switched = switchMap(outer.stream, Stream<int>.value);

      expect(switched.isBroadcast, isFalse);
    });

    test('keeps a broadcast source broadcast', () {
      final outer = ProbeStream<int>.broadcast();

      final Stream<int> switched = switchMap(outer.stream, Stream<int>.value);

      expect(switched.isBroadcast, isTrue);
    });

    test('shares one conversion per element between listeners', () async {
      final outer = ProbeStream<int>.broadcast();
      var conversions = 0;
      final Stream<int> switched = switchMap(outer.stream, (value) {
        conversions++;
        return Stream<int>.value(value);
      });
      final Future<List<int>> first = switched.toList();
      final Future<List<int>> second = switched.toList();
      await settle();

      outer.controller.add(1);
      await settle();
      await outer.controller.close();

      expect(await first, <int>[1]);
      expect(await second, <int>[1]);
      expect(conversions, 1);
      expect(outer.log, <String>['listen', 'cancel']);
    });

    test('listens to the source again for a later listener', () async {
      final outer = ProbeStream<int>.broadcast();
      final Stream<int> switched = switchMap(outer.stream, Stream<int>.value);
      final StreamSubscription<int> early = switched.listen(null);
      await settle();
      await early.cancel();

      final Future<int> next = switched.first;
      await settle();
      outer.controller.add(7);

      expect(await next, 7);
      await settle();
      expect(outer.log, <String>['listen', 'cancel', 'listen', 'cancel']);
    });
  });
}
