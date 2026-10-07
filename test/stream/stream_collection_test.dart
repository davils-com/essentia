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

import 'probe_stream.dart';

/// Checks `collect`, `launchIn`, `collectLatest`, `firstOrNull`,
/// `singleOrNull`, `firstWhereOrNull` and `countWhere`.
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

  group('collect', () {
    test('runs the action for every element in order', () async {
      final values = <int>[];

      await Stream<int>.fromIterable(<int>[1, 2, 3]).collect(values.add);

      expect(values, <int>[1, 2, 3]);
    });

    test('takes the elements and drops them without an action', () async {
      final probe = ProbeStream<int>();
      final Future<void> collected = probe.stream.collect();

      await probe.emitAll(<int>[1, 2]);
      await collected;

      expect(probe.log, <String>['listen', 'cancel']);
    });

    test('pauses the stream while an action runs', () async {
      final probe = ProbeStream<int>();
      final gate = Completer<void>();
      final Future<void> collected = probe.stream.collect((_) => gate.future);

      probe.controller.add(1);
      await settle();
      final whileRunning = List<String>.of(probe.log);
      gate.complete();
      await settle();
      final afterAction = List<String>.of(probe.log);
      await probe.emitAll(<int>[]);
      await collected;

      expect(whileRunning, <String>['listen', 'pause']);
      expect(afterAction, <String>['listen', 'pause', 'resume']);
    });

    test('fails with the first error of the stream and cancels it', () async {
      final probe = ProbeStream<int>();
      final Future<void> collected = probe.stream.collect((_) {});

      probe.controller.addError(const FormatException());

      await expectLater(collected, throwsFormatException);
      expect(probe.log, <String>['listen', 'cancel']);
    });

    test('fails with the error of an action', () async {
      final stream = Stream<int>.fromIterable(<int>[1, 2]);

      await expectLater(
        stream.collect((_) => throw const FormatException()),
        throwsFormatException,
      );
      await expectLater(
        stream.collect((_) => Future<void>.error(const FormatException())),
        throwsFormatException,
      );
    });

    test(
      'ends with the cancellation of the collecting job',
      () => runTest((it) async {
        final probe = ProbeStream<int>();
        final values = <int>[];
        Object? failure;
        final Job job = it.launch((_) async {
          try {
            await probe.stream.collect(values.add);
          } on CancellationException catch (error) {
            failure = error;
            rethrow;
          }
        });
        it.runCurrent();
        probe.controller.add(1);
        it.runCurrent();

        await job.cancelAndJoin();

        expect(values, <int>[1]);
        expect(failure, isA<CancellationException>());
        expect(probe.log, <String>['listen', 'cancel']);
      }),
    );

    test(
      'hands no element to the action once its job is cancelled',
      () => runTest((it) async {
        final values = <int>[];
        final Job job = it.launch(
          (scope) => Stream<int>.fromIterable(<int>[1, 2]).collect((value) {
            values.add(value);
            scope.cancel();
          }),
        );

        await job.join();

        expect(values, <int>[1]);
        expect(job.isCancelled, isTrue);
      }),
    );
  });

  group('launchIn', () {
    test(
      'collects in a coroutine of the scope',
      () => runTest((it) async {
        final values = <int>[];

        final Job job = Stream<int>.fromIterable(<int>[1, 2])
            .onEach(values.add)
            .launchIn(it);
        await job.join();

        expect(values, <int>[1, 2]);
        expect(job.isCompleted, isTrue);
      }),
    );

    test(
      'cancels the subscription with its job',
      () => runTest((it) async {
        final probe = ProbeStream<int>();

        final Job job = probe.stream.launchIn(it);
        it.runCurrent();
        await job.cancelAndJoin();

        expect(probe.log, <String>['listen', 'cancel']);
      }),
    );
  });

  group('firstOrNull', () {
    test('finds the first element and stops listening', () async {
      final probe = ProbeStream<int>();
      final Future<int?> first = probe.stream.firstOrNull;

      probe.controller
        ..add(1)
        ..add(2);

      expect(await first, 1);
      expect(probe.log, <String>['listen', 'cancel']);
    });

    test('finds nothing in an empty stream', () async {
      expect(await const Stream<int>.empty().firstOrNull, isNull);
    });

    test('fails with an error before the first element', () async {
      await expectLater(
        Stream<int>.error(const FormatException()).firstOrNull,
        throwsFormatException,
      );
    });
  });

  group('singleOrNull', () {
    test('finds the only element', () async {
      expect(await Stream<int>.value(1).singleOrNull, 1);
    });

    test('finds nothing in an empty stream', () async {
      expect(await const Stream<int>.empty().singleOrNull, isNull);
    });

    test('finds nothing and stops listening on a second element', () async {
      final probe = ProbeStream<int>();
      final Future<int?> single = probe.stream.singleOrNull;

      probe.controller
        ..add(1)
        ..add(2);

      expect(await single, isNull);
      expect(probe.log, <String>['listen', 'cancel']);
    });

    test('fails with an error of the stream', () async {
      await expectLater(
        Stream<int>.error(const FormatException()).singleOrNull,
        throwsFormatException,
      );
    });
  });
}
