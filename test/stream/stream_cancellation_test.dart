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

/// Covers `cancellable`: it ends a listener together with the job it
/// listened in, and passes everything else on.
void main() {
  test('passes the events on outside every job', () async {
    final stream = Stream<int>.fromIterable(<int>[1, 2]);

    await expectLater(stream.cancellable(), emitsInOrder(<Object>[1, 2]));
  });

  test('passes errors on without ending', () async {
    final probe = ProbeStream<int>();
    final Future<void> checked = expectLater(
      probe.stream.cancellable(),
      emitsInOrder(<Object>[emitsError(isFormatException), 1, emitsDone]),
    );

    probe.controller.addError(const FormatException());
    await probe.emitAll(<int>[1]);

    await checked;
  });

  test(
    'ends a listener with the cancellation of its job',
    () => runTest((it) {
      final probe = ProbeStream<int>();
      final events = <Object>[];
      var done = false;
      final Job job = it.launch((_) {
        probe.stream.cancellable().listen(
          events.add,
          onError: events.add,
          onDone: () => done = true,
        );
        return awaitCancellation();
      });
      it.runCurrent();
      probe.controller.add(1);
      it.runCurrent();

      job.cancel();
      it.runCurrent();

      expect(events.first, 1);
      expect(events.last, isA<CancellationException>());
      expect(done, isTrue);
      expect(probe.log, <String>['listen', 'cancel']);
    }),
  );

  test(
    'ends a listener at once inside a cancelled job',
    () => runTest((it) {
      final events = <Object>[];
      final parent = Job()..cancel();

      CoroutineScope(parent).launch(
        start: CoroutineStart.undispatched,
        (_) => const Stream<int>.empty().cancellable().listen(
          events.add,
          onError: events.add,
        ),
      );
      it.runCurrent();

      expect(events.single, isA<CancellationException>());
    }),
  );

  test(
    'keeps a listener of a job that completed normally',
    () => runTest((it) async {
      final probe = ProbeStream<int>();
      final values = <int>[];
      final Job job = it.launch(
        (_) => probe.stream.cancellable().listen(values.add),
      );
      await job.join();

      probe.controller.add(1);
      it.runCurrent();

      expect(values, <int>[1]);
      expect(probe.log, <String>['listen']);
    }),
  );

  test('turns a failing listen into an error event', () async {
    final controller = StreamController<int>();
    addTearDown(controller.close);
    controller.stream.listen(null);

    await expectLater(
      controller.stream.cancellable(),
      emitsInOrder(<Object>[emitsError(isStateError), emitsDone]),
    );
  });

  test('passes pause, resume and cancel on', () async {
    final probe = ProbeStream<int>();

    final List<String> log = await lifecycleOf(
      probe,
      (source) => source.cancellable(),
    );

    expect(log, <String>['listen', 'pause', 'resume', 'cancel']);
  });

  test(
    'stops watching the job once the listener cancelled',
    () => runTest((it) async {
      final probe = ProbeStream<int>();
      final events = <Object>[];
      final Job job = it.launch((_) {
        final StreamSubscription<int> subscription = probe.stream
            .cancellable()
            .listen(events.add, onError: events.add);
        return subscription.cancel();
      });
      await job.join();

      job.cancel();
      it.runCurrent();

      expect(events, isEmpty);
    }),
  );

  test('returns a shared flow as it is', () {
    final flow = MutableSharedFlow<int>();

    expect(identical(flow.cancellable(), flow), isTrue);
  });

  test('keeps a broadcast stream broadcast', () {
    final probe = ProbeStream<int>.broadcast();

    expect(probe.stream.cancellable().isBroadcast, isTrue);
    expect(ProbeStream<int>().stream.cancellable().isBroadcast, isFalse);
  });
}
