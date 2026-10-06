/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/stream/stream_collection.dart';
import 'package:test/test.dart';

import 'probe_stream.dart';

/// Checks `collectLatest`, `firstWhereOrNull` and `countWhere`.
void main() {
  group('collectLatest', () {
    test('stops waiting for the action of a superseded element', () async {
      final probe = ProbeStream<int>();
      final log = <String>[];
      final slow = Completer<void>();
      final Future<void> collected = probe.stream.collectLatest((value) async {
        log.add('start $value');
        await (value == 1 ? slow.future : Future<void>.value());
        log.add('end $value');
      });
      probe.controller.add(1);
      await settle();

      await probe.emitAll(<int>[2]);
      await collected;
      slow.complete();
      await settle();

      expect(log, <String>['start 1', 'start 2', 'end 2', 'end 1']);
    });

    test('waits for the action of the last element', () async {
      final probe = ProbeStream<int>();
      final last = Completer<void>();
      var finished = false;
      final Future<void> collected = probe.stream
          .collectLatest((_) => last.future)
          .then((_) => finished = true);

      await probe.emitAll(<int>[1]);
      await settle();
      final finishedEarly = finished;
      last.complete();
      await collected;

      expect((finishedEarly, finished), (false, true));
    });

    test('fails with the error of an awaited action', () async {
      final stream = Stream<int>.fromIterable(<int>[1]);

      final Future<void> collected = stream.collectLatest(
        (_) => Future<void>.error(const FormatException()),
      );

      await expectLater(collected, throwsFormatException);
    });

    test('fails with an error of the source', () async {
      final stream = Stream<int>.error(const FormatException());

      final Future<void> collected = stream.collectLatest((_) async {});

      await expectLater(collected, throwsFormatException);
    });
  });

  group('firstWhereOrNull', () {
    test('finds the first element that matches', () async {
      final stream = Stream<int>.fromIterable(<int>[1, 2, 3]);

      final int? even = await stream.firstWhereOrNull((value) => value.isEven);

      expect(even, 2);
    });

    test('finds nothing when no element matches', () async {
      final stream = Stream<int>.fromIterable(<int>[1, 3]);

      final int? even = await stream.firstWhereOrNull((value) => value.isEven);

      expect(even, isNull);
    });

    test('stops listening once an element matches', () async {
      final probe = ProbeStream<int>();
      final Future<int?> found = probe.stream.firstWhereOrNull(
        (value) => value.isEven,
      );

      probe.controller
        ..add(1)
        ..add(2);

      expect(await found, 2);
      expect(probe.log, <String>['listen', 'cancel']);
    });

    test('fails with an error of the source', () async {
      final stream = Stream<int>.error(const FormatException());

      final Future<int?> found = stream.firstWhereOrNull((_) => true);

      await expectLater(found, throwsFormatException);
    });

    test('fails with an error of the test', () async {
      final stream = Stream<int>.fromIterable(<int>[1]);

      final Future<int?> found = stream.firstWhereOrNull(
        (_) => throw const FormatException(),
      );

      await expectLater(found, throwsFormatException);
    });
  });

  group('countWhere', () {
    test('counts the elements that match', () async {
      final stream = Stream<int>.fromIterable(<int>[1, 2, 4]);

      final int count = await stream.countWhere((value) => value.isEven);

      expect(count, 2);
    });

    test('counts nothing in an empty stream', () async {
      const stream = Stream<int>.empty();

      final int count = await stream.countWhere((value) => value.isEven);

      expect(count, 0);
    });

    test('fails with an error of the source', () async {
      final stream = Stream<int>.error(const FormatException());

      final Future<int> count = stream.countWhere((value) => value.isEven);

      await expectLater(count, throwsFormatException);
    });
  });
}
