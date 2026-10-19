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

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_coroutines/src/stream/stream_accumulation.dart';
import 'package:test/test.dart';

import 'probe_stream.dart';

/// Adds [value] to [total].
///
/// Returns the sum.
int _sum(int total, int value) => total + value;

/// Checks `runningReduce`, `runningFold` and `scan`.
void main() {
  test('reduces step by step starting with the first element', () async {
    final stream = Stream<int>.fromIterable(<int>[1, 2, 3]);

    final List<int> sums = await stream.runningReduce(_sum).toList();

    expect(sums, <int>[1, 3, 6]);
  });

  test('emits nothing for an empty stream', () async {
    const stream = Stream<int>.empty();

    final List<int> sums = await stream.runningReduce(_sum).toList();

    expect(sums, isEmpty);
  });

  test('passes an error of the source on with its stack trace', () async {
    final StackTrace trace = StackTrace.current;
    final stream = Stream<int>.error(const FormatException(), trace);

    final StackTrace? forwarded = await stream
        .runningReduce(_sum)
        .first
        .then<StackTrace?>((_) => null, onError: (Object _, StackTrace t) => t);

    expect(forwarded, same(trace));
  });

  test('turns a failing combination into an error event', () async {
    final stream = Stream<int>.fromIterable(<int>[1, 2, 3]);

    final Stream<int> reduced = stream.runningReduce(
      (total, value) => value == 2 ? throw const FormatException() : total,
    );

    await expectLater(
      reduced,
      emitsInOrder(<Object>[1, emitsError(isFormatException), 1, emitsDone]),
    );
  });

  test('forwards pause, resume and cancel to its source', () async {
    final probe = ProbeStream<int>();

    final List<String> log = await lifecycleOf(
      probe,
      (source) => source.runningReduce(_sum),
    );

    expect(log, <String>['listen', 'pause', 'resume', 'cancel']);
  });

  test('stays a broadcast stream', () {
    final probe = ProbeStream<int>.broadcast();

    final bool broadcast = probe.stream.runningReduce(_sum).isBroadcast;

    expect(broadcast, isTrue);
  });

  test('stays a single subscription stream', () {
    final probe = ProbeStream<int>();

    final bool broadcast = probe.stream.runningReduce(_sum).isBroadcast;

    expect(broadcast, isFalse);
  });

  test('keeps a separate running value for every listener', () async {
    final probe = ProbeStream<int>.broadcast();
    final Stream<int> reduced = probe.stream.runningReduce(_sum);
    final Future<List<int>> first = reduced.toList();
    final Future<List<int>> second = reduced.toList();
    await settle();

    await probe.emitAll(<int>[1, 2]);

    expect(await Future.wait(<Future<List<int>>>[first, second]), <List<int>>[
      <int>[1, 3],
      <int>[1, 3],
    ]);
  });

  group('runningFold', () {
    test('emits the initial value and every folded value', () async {
      final stream = Stream<int>.fromIterable(<int>[1, 2, 3]);

      expect(await stream.runningFold(0, _sum).toList(), <int>[0, 1, 3, 6]);
      expect(await stream.scan(10, _sum).toList(), <int>[10, 11, 13, 16]);
    });

    test('emits the initial value of an empty stream', () async {
      expect(
        await const Stream<int>.empty().runningFold('x', (a, b) => a).toList(),
        <String>['x'],
      );
    });

    test('turns an error of the operation into an error event', () async {
      final Stream<int> folded = Stream<int>.fromIterable(<int>[1, 2, 3])
          .runningFold(0, (total, value) {
            if (value == 2) {
              throw const FormatException();
            }
            return total + value;
          });

      await expectLater(
        folded,
        emitsInOrder(<Object>[
          0,
          1,
          emitsError(isFormatException),
          4,
          emitsDone,
        ]),
      );
    });

    test('keeps a running value per listener', () async {
      final probe = ProbeStream<int>.broadcast();
      final Stream<int> folded = probe.stream.runningFold(0, _sum);
      final Future<List<int>> first = folded.toList();
      final Future<List<int>> second = folded.toList();
      await settle();

      await probe.emitAll(<int>[1, 2]);

      expect(await first, <int>[0, 1, 3]);
      expect(await second, <int>[0, 1, 3]);
    });
  });
}
