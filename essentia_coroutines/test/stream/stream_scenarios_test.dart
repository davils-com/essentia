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

/// Shorthand for a number of milliseconds.
///
/// Returns the duration.
Duration _ms(int milliseconds) => Duration(milliseconds: milliseconds);

/// Three numbers, each after 100 milliseconds, logging when the stream
/// starts.
///
/// Returns the stream.
Stream<int> _simple(List<String> log) async* {
  log.add('Flow started');
  for (var value = 1; value <= 3; value++) {
    await delay(_ms(100));
    yield value;
  }
}

/// The answers to request [value]: a first one at once and a second one
/// after 500 milliseconds.
///
/// Returns the stream.
Stream<String> _requestFlow(int value) async* {
  yield '$value: First';
  await delay(_ms(500));
  yield '$value: Second';
}

/// The numbers 1 to 3, each after [milliseconds].
///
/// Returns the stream.
Stream<int> _slowNumbers(int milliseconds) =>
    Stream<int>.fromIterable(<int>[1, 2, 3])
        .onEach((_) => delay(_ms(milliseconds)));

/// Runs typical stream scenarios on virtual time and checks the elements
/// and the moments they arrive at.
void main() {
  test(
    'cancels a flow with a timeout',
    () => runTest((it) async {
      final log = <String>[];

      await withTimeoutOrNull(
        _ms(250),
        (_) => _simple(log).collect((value) => log.add('$value')),
      );
      log.add('Done');

      expect(log, <String>['Flow started', '1', '2', 'Done']);
    }),
  );

  test(
    'runs the producer and the collector one after the other',
    () => runTest((it) async {
      final log = <String>[];

      await _simple(log).collect((value) async {
        await delay(_ms(300));
        log.add('$value');
      });

      expect(log, <String>['Flow started', '1', '2', '3']);
      expect(it.currentTime, _ms(1200));
    }),
  );

  test(
    'lets the producer run ahead with buffer',
    () => runTest((it) async {
      final log = <String>[];

      await _simple(log).buffer(64).collect((value) async {
        await delay(_ms(300));
        log.add('$value');
      });

      expect(log, <String>['Flow started', '1', '2', '3']);
      expect(it.currentTime, _ms(1000));
    }),
  );

  test(
    'skips the values a busy collector missed with conflate',
    () => runTest((it) async {
      final log = <String>[];

      await _simple(log).conflate().collect((value) async {
        await delay(_ms(300));
        log.add('$value');
      });

      expect(log, <String>['Flow started', '1', '3']);
      expect(it.currentTime, _ms(700));
    }),
  );

  test(
    'cancels a slow collector with collectLatest',
    () => runTest((it) async {
      final log = <String>[];

      await _simple(log).collectLatest((value) async {
        log.add('Collecting $value');
        await delay(_ms(300));
        log.add('Done $value');
      });

      expect(log, <String>[
        'Flow started',
        'Collecting 1',
        'Collecting 2',
        'Collecting 3',
        'Done 3',
      ]);
      expect(it.currentTime, _ms(600));
    }),
  );

  test(
    'zips two flows',
    () => runTest((it) async {
      final log = <String>[];
      final Stream<String> strings = Stream<String>.fromIterable(<String>[
        'one',
        'two',
        'three',
      ]).onEach((_) => delay(_ms(400)));

      await _slowNumbers(300)
          .zip(strings)
          .map((pair) => '${pair.$1} -> ${pair.$2}')
          .collect((value) => log.add('$value at ${it.currentTime}'));

      expect(log, <String>[
        '1 -> one at ${_ms(400)}',
        '2 -> two at ${_ms(800)}',
        '3 -> three at ${_ms(1200)}',
      ]);
    }),
  );

  test(
    'combines the latest values of two flows',
    () => runTest((it) async {
      final log = <String>[];
      final Stream<String> strings = Stream<String>.fromIterable(<String>[
        'one',
        'two',
        'three',
      ]).onEach((_) => delay(_ms(400)));

      await _slowNumbers(300)
          .combine(strings, (a, b) => '$a -> $b')
          .collect((value) => log.add('$value at ${it.currentTime}'));

      expect(log, <String>[
        '1 -> one at ${_ms(400)}',
        '2 -> one at ${_ms(600)}',
        '2 -> two at ${_ms(800)}',
        '3 -> two at ${_ms(900)}',
        '3 -> three at ${_ms(1200)}',
      ]);
    }),
  );

  test(
    'flattens with flatMapConcat',
    () => runTest((it) async {
      final log = <String>[];

      await _slowNumbers(100)
          .flatMapConcat(_requestFlow)
          .collect(
            (value) => log.add('$value at ${it.currentTime.inMilliseconds}'),
          );

      expect(log, <String>[
        '1: First at 100',
        '1: Second at 600',
        '2: First at 700',
        '2: Second at 1200',
        '3: First at 1300',
        '3: Second at 1800',
      ]);
    }),
  );

  test(
    'flattens with flatMapMerge',
    () => runTest((it) async {
      final log = <String>[];

      await _slowNumbers(100)
          .flatMapMerge(_requestFlow)
          .collect(
            (value) => log.add('$value at ${it.currentTime.inMilliseconds}'),
          );

      expect(log, <String>[
        '1: First at 100',
        '2: First at 200',
        '3: First at 300',
        '1: Second at 600',
        '2: Second at 700',
        '3: Second at 800',
      ]);
    }),
  );

  test(
    'flattens with flatMapLatest',
    () => runTest((it) async {
      final log = <String>[];

      await _slowNumbers(100)
          .flatMapLatest(_requestFlow)
          .collect(
            (value) => log.add('$value at ${it.currentTime.inMilliseconds}'),
          );

      expect(log, <String>[
        '1: First at 100',
        '2: First at 200',
        '3: First at 300',
        '3: Second at 800',
      ]);
      expect(it.currentTime, _ms(800));
    }),
  );

  test(
    'catches an exception of the upstream declaratively',
    () => runTest((it) async {
      final log = <String>[];

      await _simple(log)
          .onEach((value) {
            if (value > 1) {
              throw StateError('Collected $value');
            }
            log.add('$value');
          })
          .catchError((it, error, stackTrace) => log.add('Caught $error'))
          .collect();

      expect(log, <String>[
        'Flow started',
        '1',
        'Caught Bad state: Collected 2',
      ]);
    }),
  );

  test(
    'launches the collection of events in a scope',
    () => runTest((it) async {
      final log = <String>[];
      final Stream<int> events = Stream<int>.fromIterable(<int>[1, 2, 3])
          .onEach((_) => delay(_ms(100)));

      final Job job = events
          .onEach((event) => log.add('Event: $event'))
          .launchIn(it);
      log.add('Done');
      await job.join();

      expect(log, <String>['Done', 'Event: 1', 'Event: 2', 'Event: 3']);
    }),
  );

  test(
    'makes a busy flow cancellable',
    () => runTest((it) async {
      final log = <String>[];

      final Job job = it.launch(
        (scope) =>
            Stream<int>.fromIterable(<int>[1, 2, 3, 4, 5])
                .cancellable()
                .collect((value) {
                  if (value == 3) {
                    scope.cancel();
                  }
                  log.add('$value');
                }),
      );
      await job.join();

      expect(log, <String>['1', '2', '3']);
      expect(job.isCancelled, isTrue);
    }),
  );
}
