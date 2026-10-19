/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:test/test.dart';

import 'probe_stream.dart';

/// Checks `zip` and `combine`.
void main() {
  group('pairing', () {
    test('pairs the elements of two streams up to the shorter one', () async {
      final numbers = Stream<int>.fromIterable(<int>[1, 2, 3]);

      final List<(int, String)> pairs = await numbers
          .zip(Stream<String>.fromIterable(<String>['a', 'b']))
          .toList();

      expect(pairs, <(int, String)>[(1, 'a'), (2, 'b')]);
    });

    test('pairs by position while one stream runs ahead', () async {
      final numbers = ProbeStream<int>();
      final letters = ProbeStream<String>();
      final Future<List<(int, String)>> pairs = numbers.stream
          .zip(letters.stream)
          .toList();

      numbers.controller
        ..add(1)
        ..add(2)
        ..add(3);
      await settle();
      letters.controller.add('a');
      await settle();
      await letters.emitAll(<String>['b']);

      expect(await pairs, <(int, String)>[(1, 'a'), (2, 'b')]);
    });

    test(
      'pauses the stream that runs ahead until its partner arrives',
      () async {
        final numbers = ProbeStream<int>();
        final letters = ProbeStream<String>();
        final StreamSubscription<(int, String)> subscription = numbers.stream
            .zip(letters.stream)
            .listen(null);

        numbers.controller.add(1);
        await settle();
        final whileWaiting = List<String>.of(numbers.log);
        letters.controller.add('a');
        await settle();
        await subscription.cancel();

        expect(whileWaiting, <String>['listen', 'pause']);
        expect(numbers.log, <String>['listen', 'pause', 'resume', 'cancel']);
      },
    );

    test('ends right away when either stream is empty', () async {
      final numbers = Stream<int>.fromIterable(<int>[1, 2]);

      final List<(int, String)> pairs = await numbers
          .zip(const Stream<String>.empty())
          .toList();

      expect(pairs, isEmpty);
    });
  });

  group('ending', () {
    test('cancels the other stream when one ends', () async {
      final numbers = ProbeStream<int>();
      final letters = ProbeStream<String>();
      final Future<List<(int, String)>> pairs = numbers.stream
          .zip(letters.stream)
          .toList();
      await settle();

      await letters.emitAll(<String>[]);

      expect(await pairs, isEmpty);
      expect(numbers.log, <String>['listen', 'cancel']);
    });

    test('passes an error of either stream on', () async {
      final numbers = Stream<int>.fromIterable(<int>[1]);

      final Stream<(int, String)> pairs = numbers.zip(
        Stream<String>.error(const FormatException()),
      );

      await expectLater(pairs, emitsError(isFormatException));
    });

    test('ends after the first error and cancels both streams', () async {
      final numbers = ProbeStream<int>();
      final letters = ProbeStream<String>();
      final Stream<(int, String)> pairs = numbers.stream.zip(letters.stream);

      final Future<void> checked = expectLater(
        pairs,
        emitsInOrder(<Object>[emitsError(isFormatException), emitsDone]),
      );
      await settle();
      numbers.controller.addError(const FormatException());
      await checked;

      expect(numbers.log, <String>['listen', 'cancel']);
      expect(letters.log, <String>['listen', 'cancel']);
    });
  });

  group('subscription', () {
    test('forwards pause, resume and cancel to both streams', () async {
      final numbers = ProbeStream<int>();
      final letters = ProbeStream<String>();

      final List<String> log = await lifecycleOf(
        numbers,
        (source) => source.zip(letters.stream),
      );

      const lifecycle = <String>['listen', 'pause', 'resume', 'cancel'];
      expect(log, lifecycle);
      expect(letters.log, lifecycle);
    });

    test('is a single subscription stream even for broadcast sources', () {
      final numbers = ProbeStream<int>.broadcast();
      final letters = ProbeStream<String>.broadcast();

      final bool broadcast = numbers.stream.zip(letters.stream).isBroadcast;

      expect(broadcast, isFalse);
    });

    test('gives every listener its own pairing', () async {
      final numbers = ProbeStream<int>.broadcast();
      final letters = ProbeStream<String>.broadcast();
      final Stream<(int, String)> zipped = numbers.stream.zip(letters.stream);
      final Future<List<(int, String)>> first = zipped.toList();
      final Future<List<(int, String)>> second = zipped.toList();
      await settle();

      numbers.controller.add(1);
      await letters.emitAll(<String>['a']);

      expect(
        await Future.wait(<Future<List<(int, String)>>>[first, second]),
        <List<(int, String)>>[
          <(int, String)>[(1, 'a')],
          <(int, String)>[(1, 'a')],
        ],
      );
    });
  });

  group('combine', () {
    test('combines the latest elements once both emitted', () async {
      final left = ProbeStream<int>();
      final right = ProbeStream<String>();
      final Future<List<String>> combined = left.stream
          .combine(right.stream, (a, b) => '$a$b')
          .toList();

      left.controller.add(1);
      await settle();
      left.controller.add(2);
      await settle();
      right.controller.add('a');
      await settle();
      left.controller.add(3);
      await settle();
      right.controller.add('b');
      await settle();
      await left.emitAll(<int>[]);
      await right.emitAll(<String>[]);

      expect(await combined, <String>['2a', '3a', '3b']);
    });

    test('passes errors of both streams and of the transform on', () async {
      final left = ProbeStream<int>();
      final right = ProbeStream<int>();
      final Future<void> checked = expectLater(
        left.stream.combine(right.stream, (a, b) {
          if (a == 0) {
            throw const FormatException('transform');
          }
          return a + b;
        }),
        emitsInOrder(<Object>[
          emitsError(isStateError),
          emitsError(isFormatException),
          11,
          emitsDone,
        ]),
      );

      right.controller
        ..addError(StateError('right'))
        ..add(10);
      await settle();
      left.controller.add(0);
      await settle();
      left.controller.add(1);
      await settle();
      await left.emitAll(<int>[]);
      await right.emitAll(<int>[]);

      await checked;
    });

    test('passes pause, resume and cancel to both streams', () async {
      final left = ProbeStream<int>();
      final right = ProbeStream<int>();

      final List<String> log = await lifecycleOf(
        left,
        (source) => source.combine(right.stream, (a, b) => a + b),
      );

      const lifecycle = <String>['listen', 'pause', 'resume', 'cancel'];
      expect(log, lifecycle);
      expect(right.log, lifecycle);
    });

    test('combines a list of streams with the top level combine', () async {
      final Stream<int> total = combine(<Stream<int>>[
        Stream<int>.value(1),
        Stream<int>.value(2),
        Stream<int>.value(3),
      ], (values) => values.fold(0, (sum, value) => sum + value));

      expect(await total.last, 6);
    });

    test('ends at once without streams', () async {
      await expectLater(
        combine(<Stream<int>>[], (values) => values.length),
        emitsDone,
      );
    });

    test('hands the transform an unmodifiable snapshot', () async {
      final List<List<int>> snapshots = await combine(<Stream<int>>[
        Stream<int>.value(1),
      ], (values) => values).toList();

      expect(() => snapshots.single.add(2), throwsUnsupportedError);
    });
  });
}
