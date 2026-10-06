/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/stream/stream_mapping.dart';
import 'package:test/test.dart';

import 'probe_stream.dart';

/// Checks `mapNotNull`, `indexed`, `mapLatest` and `flatMapMerge`.
void main() {
  group('mapNotNull', () {
    test('maps and keeps only the present results', () async {
      final stream = Stream<String>.fromIterable(<String>['1', 'x', '3']);

      final List<int> numbers = await stream.mapNotNull(int.tryParse).toList();

      expect(numbers, <int>[1, 3]);
    });

    test('turns a failing transform into an error event', () async {
      final stream = Stream<String>.fromIterable(<String>['1', 'x', '3']);

      final Stream<int> numbers = stream.mapNotNull(int.parse);

      await expectLater(
        numbers,
        emitsInOrder(<Object>[1, emitsError(isFormatException), 3, emitsDone]),
      );
    });

    test('stays a broadcast stream', () {
      final probe = ProbeStream<String>.broadcast();

      final bool broadcast = probe.stream.mapNotNull(int.tryParse).isBroadcast;

      expect(broadcast, isTrue);
    });
  });

  group('indexed', () {
    test('pairs every element with its index', () async {
      final stream = Stream<String>.fromIterable(<String>['a', 'b']);

      final List<(int, String)> indexed = await stream.indexed.toList();

      expect(indexed, <(int, String)>[(0, 'a'), (1, 'b')]);
    });

    test('forwards pause, resume and cancel while indexing', () async {
      final probe = ProbeStream<int>();

      final List<String> log = await lifecycleOf(
        probe,
        (source) => source.indexed,
      );

      expect(log, <String>['listen', 'pause', 'resume', 'cancel']);
    });

    test('passes an error on while indexing', () async {
      final stream = Stream<int>.error(const FormatException());

      await expectLater(stream.indexed, emitsError(isFormatException));
    });

    test('counts from zero for every listener', () async {
      final probe = ProbeStream<String>.broadcast();
      final Stream<(int, String)> indexed = probe.stream.indexed;
      final Future<List<(int, String)>> first = indexed.toList();
      probe.controller.add('a');
      await settle();
      final Future<List<(int, String)>> second = indexed.toList();
      await settle();

      await probe.emitAll(<String>['b']);

      expect(await first, <(int, String)>[(0, 'a'), (1, 'b')]);
      expect(await second, <(int, String)>[(0, 'b')]);
    });
  });

  group('mapLatest', () {
    test('keeps only the result of the latest element', () async {
      final probe = ProbeStream<int>();
      final slow = Completer<String>();
      final Future<List<String>> results = probe.stream
          .mapLatest(
            (value) => value == 1 ? slow.future : Future<String>.value('two'),
          )
          .toList();
      probe.controller.add(1);
      await settle();

      await probe.emitAll(<int>[2]);
      slow.complete('one');

      expect(await results, <String>['two']);
    });

    test('emits every result that arrives before the next element', () async {
      final probe = ProbeStream<int>();
      final Future<List<int>> results = probe.stream
          .mapLatest((value) async => value * 10)
          .toList();

      probe.controller.add(1);
      await settle();
      await probe.emitAll(<int>[2]);

      expect(await results, <int>[10, 20]);
    });

    test('passes the error of a failing transform on', () async {
      final stream = Stream<int>.fromIterable(<int>[1]);

      final Stream<int> results = stream.mapLatest(
        (_) => Future<int>.error(const FormatException()),
      );

      await expectLater(
        results,
        emitsInOrder(<Object>[emitsError(isFormatException), emitsDone]),
      );
    });
  });

  group('flatMapMerge', () {
    test('merges the inner streams of every element', () async {
      final stream = Stream<int>.fromIterable(<int>[1, 2]);

      final List<int> merged = await stream
          .flatMapMerge(
            (value) => Stream<int>.fromIterable(<int>[value, value * 10]),
          )
          .toList();

      expect(merged, unorderedEquals(<int>[1, 10, 2, 20]));
    });

    test('opens no more inner streams than the concurrency allows', () async {
      final first = ProbeStream<int>();
      final second = ProbeStream<int>();
      final inners = <int, ProbeStream<int>>{1: first, 2: second};
      final Future<List<int>> merged = Stream<int>.fromIterable(<int>[1, 2])
          .flatMapMerge((value) => inners[value]!.stream, concurrency: 1)
          .toList();
      await settle();

      final secondBefore = List<String>.of(second.log);

      await first.emitAll(<int>[1]);
      await settle();
      await second.emitAll(<int>[2]);
      expect(secondBefore, isEmpty);
      expect(await merged, <int>[1, 2]);
    });

    test('runs inner streams within the concurrency side by side', () async {
      final first = ProbeStream<int>();
      final second = ProbeStream<int>();
      final inners = <int, ProbeStream<int>>{1: first, 2: second};
      final Future<List<int>> merged = Stream<int>.fromIterable(<int>[1, 2])
          .flatMapMerge((value) => inners[value]!.stream, concurrency: 2)
          .toList();
      await settle();

      second.controller.add(20);
      await settle();
      first.controller.add(10);
      await settle();
      await second.emitAll(<int>[]);
      await first.emitAll(<int>[]);

      expect(await merged, <int>[20, 10]);
    });

    test('refuses a concurrency below one', () {
      const stream = Stream<int>.empty();

      Stream<int> merge() => stream.flatMapMerge(
        (value) => const Stream<int>.empty(),
        concurrency: 0,
      );

      expect(merge, throwsRangeError);
    });

    test('turns a failing transform into an error event', () async {
      final stream = Stream<int>.fromIterable(<int>[1, 2]);

      final Stream<int> merged = stream.flatMapMerge(
        (value) => value == 1
            ? throw const FormatException()
            : Stream<int>.value(value),
      );

      await expectLater(
        merged,
        emitsInOrder(<Object>[emitsError(isFormatException), 2, emitsDone]),
      );
    });

    test('passes an error of an inner stream on and keeps going', () async {
      final stream = Stream<int>.fromIterable(<int>[1, 2]);

      final Stream<int> merged = stream.flatMapMerge(
        (value) => value == 1
            ? Stream<int>.error(const FormatException())
            : Stream<int>.value(value),
        concurrency: 1,
      );

      await expectLater(
        merged,
        emitsInOrder(<Object>[emitsError(isFormatException), 2, emitsDone]),
      );
    });

    test('never opens an inner stream after the listener cancelled', () async {
      final running = ProbeStream<int>();
      var opened = 0;
      final probe = ProbeStream<int>();
      final Stream<int> merged = probe.stream.flatMapMerge((value) {
        opened++;
        return value == 1 ? running.stream : const Stream<int>.empty();
      }, concurrency: 1);
      final StreamSubscription<int> subscription = merged.listen(null);
      probe.controller
        ..add(1)
        ..add(2);
      await settle();

      await subscription.cancel();
      await settle();

      expect(opened, 1);
      expect(running.log, <String>['listen', 'cancel']);
    });

    test('frees the permit of a cancelled inner stream', () async {
      final source = ProbeStream<int>.broadcast();
      final inner = ProbeStream<int>();
      final Stream<int> merged = source.stream.flatMapMerge(
        (value) => value == 1 ? inner.stream : Stream<int>.value(value),
        concurrency: 1,
      );
      final StreamSubscription<int> subscription = merged.listen(null);
      source.controller.add(1);
      await settle();
      await subscription.cancel();

      final Future<int> next = merged.first;
      await settle();
      source.controller.add(2);

      expect(await next, 2);
      expect(inner.log, <String>['listen', 'cancel']);
    });

    test('limits the inner streams of a broadcast source', () async {
      final first = ProbeStream<int>();
      final second = ProbeStream<int>();
      final inners = <int, ProbeStream<int>>{1: first, 2: second};
      final source = ProbeStream<int>.broadcast();
      final Stream<int> merged = source.stream.flatMapMerge(
        (value) => inners[value]!.stream,
        concurrency: 1,
      );
      final Future<List<int>> results = merged.toList();
      await settle();

      source.controller
        ..add(1)
        ..add(2);
      await settle();
      final secondBefore = List<String>.of(second.log);
      await first.emitAll(<int>[1]);
      await settle();
      await second.emitAll(<int>[2]);
      await source.controller.close();

      expect(secondBefore, isEmpty);
      expect(await results, <int>[1, 2]);
    });

    test('forwards pause, resume and cancel to its source', () async {
      final probe = ProbeStream<int>();

      final List<String> log = await lifecycleOf(
        probe,
        (source) => source.flatMapMerge(Stream<int>.value),
      );

      expect(log, <String>['listen', 'pause', 'resume', 'cancel']);
    });

    test('stays a broadcast stream', () {
      final probe = ProbeStream<int>.broadcast();

      final bool broadcast = probe.stream
          .flatMapMerge(Stream<int>.value)
          .isBroadcast;

      expect(broadcast, isTrue);
    });
  });
}
