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
import 'package:essentia_coroutines/src/stream/stream_lifecycle.dart';
import 'package:test/test.dart';

import 'probe_stream.dart';

/// Checks `onStart`, `onCompletion` and `onEmpty`.
void main() {
  group('onStart', () {
    test('runs the start action before the first element', () async {
      final log = <String>[];
      final stream = Stream<String>.fromIterable(<String>['element']);

      await stream.onStart(() => log.add('start')).forEach(log.add);

      expect(log, <String>['start', 'element']);
    });

    test('runs the start action for every listener', () async {
      final probe = ProbeStream<int>.broadcast();
      var starts = 0;
      final Stream<int> started = probe.stream.onStart(() => starts++);
      final Future<List<int>> first = started.toList();
      final Future<List<int>> second = started.toList();
      await settle();

      await probe.emitAll(<int>[1]);
      await Future.wait(<Future<List<int>>>[first, second]);

      expect(starts, 2);
    });

    test('reports a failing start action as an error and ends', () async {
      final probe = ProbeStream<int>();

      final Stream<int> started = probe.stream.onStart(
        () => throw const FormatException(),
      );

      await expectLater(
        started,
        emitsInOrder(<Object>[emitsError(isFormatException), emitsDone]),
      );
      expect(probe.log, isEmpty);
    });

    test('forwards pause, resume and cancel after starting', () async {
      final probe = ProbeStream<int>();

      final List<String> log = await lifecycleOf(
        probe,
        (source) => source.onStart(() {}),
      );

      expect(log, <String>['listen', 'pause', 'resume', 'cancel']);
    });

    test('stays a broadcast stream', () {
      final probe = ProbeStream<int>.broadcast();

      final bool broadcast = probe.stream.onStart(() {}).isBroadcast;

      expect(broadcast, isTrue);
    });
  });

  group('onCompletion', () {
    test('runs the completion action after the last element', () async {
      final log = <String>[];
      final stream = Stream<String>.fromIterable(<String>['element']);

      await stream.onCompletion(() => log.add('completed')).forEach(log.add);

      expect(log, <String>['element', 'completed']);
    });

    test('runs the completion action when the listener cancels', () async {
      final log = <String>[];
      final probe = ProbeStream<int>();

      await lifecycleOf(
        probe,
        (source) => source.onCompletion(() => log.add('completed')),
      );

      expect(log, <String>['completed']);
    });

    test('runs the completion action only once', () async {
      var completions = 0;
      final stream = Stream<int>.fromIterable(<int>[1]);

      await stream.onCompletion(() => completions++).first;

      expect(completions, 1);
    });

    test('reports a failing completion action as an error', () async {
      const stream = Stream<int>.empty();

      final Stream<int> completed = stream.onCompletion(
        () => throw const FormatException(),
      );

      await expectLater(
        completed,
        emitsInOrder(<Object>[emitsError(isFormatException), emitsDone]),
      );
    });

    test('passes errors on before completing', () async {
      final stream = Stream<int>.error(const FormatException());

      await expectLater(
        stream.onCompletion(() {}),
        emitsInOrder(<Object>[emitsError(isFormatException), emitsDone]),
      );
    });

    test('forwards pause and resume before completing', () async {
      final probe = ProbeStream<int>();

      final List<String> log = await lifecycleOf(
        probe,
        (source) => source.onCompletion(() {}),
      );

      expect(log, <String>['listen', 'pause', 'resume', 'cancel']);
    });

    test('stays a broadcast stream when watching for completion', () {
      final probe = ProbeStream<int>.broadcast();

      final bool broadcast = probe.stream.onCompletion(() {}).isBroadcast;

      expect(broadcast, isTrue);
    });
  });

  group('onEmpty', () {
    test('emits the fallback when the source is empty', () async {
      const stream = Stream<int>.empty();

      final List<int> values = await stream
          .onEmpty(() => Stream<int>.value(9))
          .toList();

      expect(values, <int>[9]);
    });

    test('keeps the elements of a source that is not empty', () async {
      final stream = Stream<int>.fromIterable(<int>[1, 2]);

      final List<int> values = await stream
          .onEmpty(() => Stream<int>.value(9))
          .toList();

      expect(values, <int>[1, 2]);
    });

    test('counts only elements, not errors, as content', () async {
      final stream = Stream<int>.error(const FormatException());

      await expectLater(
        stream.onEmpty(() => Stream<int>.value(9)),
        emitsInOrder(<Object>[emitsError(isFormatException), 9, emitsDone]),
      );
    });

    test(
      'forwards pause, resume and cancel while waiting for elements',
      () async {
        final probe = ProbeStream<int>();

        final List<String> log = await lifecycleOf(
          probe,
          (source) => source.onEmpty(Stream<int>.empty),
        );

        expect(log, <String>['listen', 'pause', 'resume', 'cancel']);
      },
    );
  });
}
