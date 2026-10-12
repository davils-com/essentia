/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/stream/concurrent_async_expand.dart';
import 'package:test/test.dart';

import 'probe_stream.dart';

/// Checks the concurrent merging that `flatMapMerge` builds on.
void main() {
  group('ordering', () {
    test('emits events in the order the inner streams emit them', () async {
      final outer = ProbeStream<int>();
      final first = ProbeStream<String>();
      final second = ProbeStream<String>();
      final inners = <int, ProbeStream<String>>{1: first, 2: second};
      final Future<List<String>> events = concurrentAsyncExpand(
        outer.stream,
        (value) => inners[value]!.stream,
      ).toList();

      await outer.emitAll(<int>[1, 2]);
      await settle();
      first.controller.add('a1');
      await settle();
      second.controller.add('b1');
      await settle();
      first.controller.add('a2');
      await settle();
      await second.emitAll(<String>['b2']);
      await first.emitAll(<String>[]);

      expect(await events, <String>['a1', 'b1', 'a2', 'b2']);
    });

    test('listens to every inner stream at once', () async {
      final first = ProbeStream<String>();
      final second = ProbeStream<String>();
      final inners = <int, ProbeStream<String>>{1: first, 2: second};
      final StreamSubscription<String> subscription = concurrentAsyncExpand(
        Stream<int>.fromIterable(<int>[1, 2]),
        (value) => inners[value]!.stream,
      ).listen(null);
      await settle();

      final firstLog = List<String>.of(first.log);
      final secondLog = List<String>.of(second.log);
      await subscription.cancel();

      expect(firstLog, <String>['listen']);
      expect(secondLog, <String>['listen']);
    });
  });

  group('completion', () {
    test('ends only once the source and every inner stream ended', () async {
      final first = ProbeStream<int>();
      final second = ProbeStream<int>();
      final inners = <int, ProbeStream<int>>{1: first, 2: second};
      var done = false;
      final Future<void> drained = concurrentAsyncExpand(
        Stream<int>.fromIterable(<int>[1, 2]),
        (value) => inners[value]!.stream,
      ).drain<void>().then((_) => done = true);
      await settle();

      await first.emitAll(<int>[]);
      await settle();
      final doneEarly = done;
      await second.emitAll(<int>[]);
      await drained;

      expect((doneEarly, done), (false, true));
    });

    test('ends with an empty source', () async {
      final Stream<int> merged = concurrentAsyncExpand(
        const Stream<int>.empty(),
        Stream<int>.value,
      );

      await expectLater(merged, emitsDone);
    });

    test('waits for the source even when every inner stream ended', () async {
      final outer = ProbeStream<int>();
      var done = false;
      final Future<void> drained = concurrentAsyncExpand(
        outer.stream,
        Stream<int>.value,
      ).drain<void>().then((_) => done = true);

      outer.controller.add(1);
      await settle();
      final doneEarly = done;
      await outer.controller.close();
      await drained;

      expect((doneEarly, done), (false, true));
    });
  });

  group('errors', () {
    test('passes errors of the source on and keeps going', () async {
      final outer = ProbeStream<int>();
      final Stream<int> merged = concurrentAsyncExpand(
        outer.stream,
        Stream<int>.value,
      );
      final Future<void> checked = expectLater(
        merged,
        emitsInOrder(<Object>[emitsError(isFormatException), 1, emitsDone]),
      );

      outer.controller.addError(const FormatException());
      await outer.emitAll(<int>[1]);

      await checked;
    });

    test('passes errors of an inner stream on and keeps going', () async {
      final Stream<int> merged = concurrentAsyncExpand(
        Stream<int>.fromIterable(<int>[1, 2]),
        (value) => value == 1
            ? Stream<int>.error(const FormatException())
            : Stream<int>.value(value),
      );

      await expectLater(
        merged,
        emitsInOrder(<Object>[emitsError(isFormatException), 2, emitsDone]),
      );
    });

    test('passes an error of the conversion on and keeps going', () async {
      final Stream<int> merged = concurrentAsyncExpand(
        Stream<int>.fromIterable(<int>[1, 2]),
        (value) => value == 1
            ? throw const FormatException()
            : Stream<int>.value(value),
      );

      await expectLater(
        merged,
        emitsInOrder(<Object>[emitsError(isFormatException), 2, emitsDone]),
      );
    });
  });

  group('pause, resume and cancel', () {
    test('reach the source and every inner stream', () async {
      final outer = ProbeStream<int>();
      final first = ProbeStream<String>();
      final second = ProbeStream<String>();
      final inners = <int, ProbeStream<String>>{1: first, 2: second};
      final StreamSubscription<String> subscription = concurrentAsyncExpand(
        outer.stream,
        (value) => inners[value]!.stream,
      ).listen(null);
      outer.controller
        ..add(1)
        ..add(2);
      await settle();

      subscription.pause();
      await settle();
      subscription.resume();
      await settle();
      await subscription.cancel();

      const lifecycle = <String>['listen', 'pause', 'resume', 'cancel'];
      expect(outer.log, lifecycle);
      expect(first.log, lifecycle);
      expect(second.log, lifecycle);
    });

    test('hold back the events of the inner streams', () async {
      final outer = ProbeStream<int>();
      final inner = ProbeStream<String>();
      final events = <String>[];
      final StreamSubscription<String> subscription = concurrentAsyncExpand(
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
  });

  group('broadcast', () {
    test('keeps a single subscription source single subscription', () {
      final outer = ProbeStream<int>();

      final Stream<int> merged = concurrentAsyncExpand(
        outer.stream,
        Stream<int>.value,
      );

      expect(merged.isBroadcast, isFalse);
    });

    test('keeps a broadcast source broadcast', () {
      final outer = ProbeStream<int>.broadcast();

      final Stream<int> merged = concurrentAsyncExpand(
        outer.stream,
        Stream<int>.value,
      );

      expect(merged.isBroadcast, isTrue);
    });

    test('shares one conversion per element between listeners', () async {
      final outer = ProbeStream<int>.broadcast();
      var conversions = 0;
      final Stream<int> merged = concurrentAsyncExpand(outer.stream, (value) {
        conversions++;
        return Stream<int>.value(value);
      });
      final Future<List<int>> first = merged.toList();
      final Future<List<int>> second = merged.toList();
      await settle();

      outer.controller.add(1);
      await settle();
      await outer.controller.close();

      expect(await first, <int>[1]);
      expect(await second, <int>[1]);
      expect(conversions, 1);
    });
  });
}
