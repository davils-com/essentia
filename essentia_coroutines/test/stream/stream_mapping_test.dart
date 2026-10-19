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
import 'package:essentia_coroutines/testing.dart';
import 'package:test/test.dart';

import 'probe_stream.dart';

/// The numbers 1 and 2, the second one 100 milliseconds after the first,
/// so that the work for the first one ends in time.
///
/// Returns the stream.
Stream<int> _spaced() =>
    Stream<int>.fromIterable(<int>[1, 2])
        .onEach((value) => delay(Duration(milliseconds: value == 1 ? 0 : 100)));

/// The numbers 1 and 2, the second one 100 milliseconds after the first,
/// so that slow work for the first one is superseded.
///
/// Returns the stream.
Stream<int> _spacedLong() =>
    Stream<int>.fromIterable(<int>[1, 2])
        .onEach((value) => delay(Duration(milliseconds: value == 1 ? 0 : 100)));

/// Checks `mapNotNull`, `indexed`, `mapLatest`, `flatMapMerge`,
/// `flatMapLatest`, `flatMapConcat`, `transformLatest` and `onEach`.
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

  group('cancelling the superseded work', () {
    test(
      'cancels the delay of a superseded mapLatest transform',
      () => runTest((it) async {
        final log = <String>[];
        final Stream<int> numbers = Stream<int>.fromIterable(<int>[1, 2])
            .onEach((_) => delay(const Duration(milliseconds: 100)));

        final List<String> results = await numbers.mapLatest((value) async {
          try {
            await delay(const Duration(milliseconds: 150));
          } on CancellationException {
            log.add('cancelled $value');
            rethrow;
          }
          return 'mapped $value';
        }).toList();

        expect(results, <String>['mapped 2']);
        expect(log, <String>['cancelled 1']);
        expect(it.currentTime, const Duration(milliseconds: 350));
      }),
    );

    test(
      'cancels the work of the current inner stream with the job',
      () => runTest((it) async {
        final log = <String>[];
        final Job job = it.launch(
          (_) => Stream<int>.value(1).flatMapLatest((value) async* {
            try {
              await awaitCancellation();
            } finally {
              log.add('inner ended');
            }
          }).collect(),
        );
        it.runCurrent();

        await job.cancelAndJoin();

        expect(log, <String>['inner ended']);
        expect(job.isCancelled, isTrue);
      }),
    );
  });

  group('flatMapLatest', () {
    test(
      'emits the events of the inner streams that end in time',
      () => runTest((it) async {
        final List<int> values = await _spaced()
            .flatMapLatest(
              (value) => Stream<int>.fromIterable(<int>[value, 10]),
            )
            .toList();

        expect(values, <int>[1, 10, 2, 10]);
      }),
    );

    test('keeps a broadcast source broadcast', () {
      final probe = ProbeStream<int>.broadcast();

      expect(probe.stream.flatMapLatest(Stream<int>.value).isBroadcast, isTrue);
    });
  });

  group('flatMapConcat', () {
    test('emits the inner streams one after the other', () async {
      final numbers = Stream<int>.fromIterable(<int>[1, 2]);

      final List<int> values = await numbers
          .flatMapConcat((value) => Stream<int>.fromIterable(<int>[value, 10]))
          .toList();

      expect(values, <int>[1, 10, 2, 10]);
    });
  });

  group('transformLatest', () {
    test(
      'emits what the run of every element emits',
      () => runTest((it) async {
        final List<String> values = await _spaced().transformLatest<String>((
          collector,
          value,
        ) async {
          await collector.emit('a$value');
          await collector.emit('b$value');
        }).toList();

        expect(values, <String>['a1', 'b1', 'a2', 'b2']);
      }),
    );

    test(
      'cancels the run of the previous element',
      () => runTest((it) async {
        final log = <String>[];
        final Stream<int> numbers = Stream<int>.fromIterable(<int>[1, 2])
            .onEach((_) => delay(const Duration(milliseconds: 100)));

        final List<String> values = await numbers.transformLatest<String>((
          collector,
          value,
        ) async {
          await collector.emit('start $value');
          try {
            await delay(const Duration(milliseconds: 150));
          } on CancellationException {
            log.add('cancelled $value');
            rethrow;
          }
          await collector.emit('end $value');
        }).toList();

        expect(values, <String>['start 1', 'start 2', 'end 2']);
        expect(log, <String>['cancelled 1']);
      }),
    );

    test(
      'passes an error of a run on and keeps going',
      () => runTest((it) async {
        final Stream<int> values = _spaced().transformLatest<int>((
          collector,
          value,
        ) async {
          if (value == 1) {
            throw const FormatException();
          }
          await collector.emit(value);
        });

        await expectLater(
          values,
          emitsInOrder(<Object>[emitsError(isFormatException), 2, emitsDone]),
        );
      }),
    );

    test('passes a cancellation a run throws by itself on', () async {
      final Stream<int> values = Stream<int>.value(1).transformLatest<int>(
        (it, value) => throw const CancellationException('own'),
      );

      await expectLater(
        values,
        emitsInOrder(<Object>[
          emitsError(isA<CancellationException>()),
          emitsDone,
        ]),
      );
    });

    test('waits in emit while the listener is paused', () async {
      final log = <String>[];
      final StreamSubscription<String> subscription = Stream<int>.value(1)
          .transformLatest<String>((it, value) async {
            await it.emit('first');
            log.add('emitted first');
            await it.emit('second');
            log.add('emitted second');
          })
          .listen(log.add);
      addTearDown(subscription.cancel);
      subscription.pause();
      await settle();
      final whilePaused = List<String>.of(log);

      subscription.resume();
      await settle();

      expect(whilePaused, isEmpty);
      expect(log, <String>[
        'first',
        'emitted first',
        'second',
        'emitted second',
      ]);
    });

    test('fails an emit once the listener cancelled', () async {
      final failure = Completer<Object>();
      final StreamSubscription<int> subscription = Stream<int>.value(1)
          .transformLatest<int>((it, value) async {
            await settle();
            try {
              await it.emit(value);
            } on Object catch (error) {
              failure.complete(error);
            }
          })
          .listen(null);
      await Future<void>.value();

      await subscription.cancel();

      expect(await failure.future, isA<CancellationException>());
    });
  });

  group('transformLatest emit', () {
    test(
      'waits while a slow listener processes an element',
      () => runTest((it) async {
        final log = <String>[];
        final Stream<String> values = Stream<int>.value(1)
            .transformLatest<String>((collector, value) async {
              await collector.emit('first');
              log.add('emitted first');
              await collector.emit('second');
              log.add('emitted second');
            });

        await values.collect((value) async {
          log.add('got $value');
          await delay(const Duration(milliseconds: 100));
          log.add('done $value');
        });

        expect(log, <String>[
          'got first',
          'emitted first',
          'done first',
          'got second',
          'done second',
          'emitted second',
        ]);
      }),
    );

    test(
      'refuses to emit from a superseded run',
      () => runTest((it) async {
        final log = <String>[];

        final List<String> values = await _spacedLong().transformLatest<String>(
          (collector, value) async {
            try {
              await delay(const Duration(milliseconds: 150));
            } on CancellationException {
              try {
                await collector.emit('late $value');
              } on CancellationException {
                log.add('refused $value');
              }
              rethrow;
            }
            await collector.emit('end $value');
          },
        ).toList();

        expect(values, <String>['end 2']);
        expect(log, <String>['refused 1']);
      }),
    );
  });

  group('onEach', () {
    test('runs the action before every element is emitted', () async {
      final log = <String>[];

      await Stream<int>.fromIterable(<int>[1, 2])
          .onEach((value) => log.add('saw $value'))
          .onEach((value) => log.add('awaited $value'))
          .forEach((value) => log.add('got $value'));

      expect(log, <String>[
        'saw 1',
        'awaited 1',
        'got 1',
        'saw 2',
        'awaited 2',
        'got 2',
      ]);
    });

    test('turns an error of the action into an error event', () async {
      final Stream<int> stream = Stream<int>.fromIterable(<int>[1, 2])
          .onEach((value) => value == 1 ? throw const FormatException() : null);

      await expectLater(
        stream,
        emitsInOrder(<Object>[emitsError(isFormatException), 2, emitsDone]),
      );
    });
  });
}
