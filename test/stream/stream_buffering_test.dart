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
import 'package:test/test.dart';

import 'probe_stream.dart';

/// Listens to [stream] collecting its events into [events], paused until
/// the test resumes it.
///
/// Returns the function that resumes the subscription.
void Function() _pausedListener(Stream<int> stream, List<Object> events) {
  final StreamSubscription<int> subscription = stream.listen(
    events.add,
    onError: events.add,
    onDone: () => events.add('done'),
  )..pause();
  addTearDown(subscription.cancel);
  return subscription.resume;
}

/// Covers `buffer` and `conflate`: buffering for a paused listener, every
/// overflow policy and the validation of the capacity.
void main() {
  group('validation', () {
    test('refuses a negative capacity other than the special ones', () {
      expect(
        () => const Stream<int>.empty().buffer(-3),
        throwsA(
          isArgumentError.having(
            (error) => error.message,
            'message',
            'Buffer size should be non-negative, BUFFERED, or CONFLATED, but '
                'was -3',
          ),
        ),
      );
    });

    test('refuses conflation with a dropping policy', () {
      expect(
        () => const Stream<int>.empty().buffer(
          -1,
          onBufferOverflow: BufferOverflow.dropLatest,
        ),
        throwsA(
          isArgumentError.having(
            (error) => error.message,
            'message',
            'CONFLATED capacity cannot be used with non-default '
                'onBufferOverflow',
          ),
        ),
      );
    });
  });

  group('suspend', () {
    test('pauses the stream once the buffer is full', () async {
      final probe = ProbeStream<int>();
      final events = <Object>[];
      final void Function() resume = _pausedListener(
        probe.stream.buffer(2),
        events,
      );
      await settle();

      probe.controller
        ..add(1)
        ..add(2);
      await settle();
      final beforeFull = List<String>.of(probe.log);
      probe.controller.add(3);
      await settle();
      final whenFull = List<String>.of(probe.log);
      resume();
      await settle();

      expect(beforeFull, <String>['listen']);
      expect(whenFull, <String>['listen', 'pause']);
      expect(probe.log, <String>['listen', 'pause', 'resume']);
      expect(events, <Object>[1, 2, 3]);
    });

    test('hands every element over without a buffer', () async {
      final probe = ProbeStream<int>();
      final values = <int>[];
      final StreamSubscription<int> subscription = probe.stream
          .buffer(0)
          .listen(values.add);
      addTearDown(subscription.cancel);
      await settle();

      probe.controller
        ..add(1)
        ..add(2);
      await settle();

      expect(values, <int>[1, 2]);
    });

    test('buffers 64 elements by default', () async {
      final events = <Object>[];
      final void Function() resume = _pausedListener(
        Stream<int>.fromIterable(List<int>.generate(70, (index) => index))
            .buffer(-2),
        events,
      );
      await settle();
      final whilePaused = List<Object>.of(events);

      resume();
      await settle();
      await settle();

      expect(whilePaused, isEmpty);
      expect(events, <Object>[...List<int>.generate(70, (i) => i), 'done']);
    });
  });

  group('dropping', () {
    test('drops the oldest elements when the buffer is full', () async {
      final probe = ProbeStream<int>();
      final events = <Object>[];
      final void Function() resume = _pausedListener(
        probe.stream.buffer(2, onBufferOverflow: BufferOverflow.dropOldest),
        events,
      );
      await settle();

      await probe.emitAll(<int>[1, 2, 3, 4]);
      resume();
      await settle();

      expect(events, <Object>[3, 4, 'done']);
    });

    test('drops the newest elements when the buffer is full', () async {
      final probe = ProbeStream<int>();
      final events = <Object>[];
      final void Function() resume = _pausedListener(
        probe.stream.buffer(2, onBufferOverflow: BufferOverflow.dropLatest),
        events,
      );
      await settle();

      await probe.emitAll(<int>[1, 2, 3, 4]);
      resume();
      await settle();

      expect(events, <Object>[1, 2, 'done']);
    });

    test('keeps one element for a dropping buffer of zero', () async {
      final probe = ProbeStream<int>();
      final events = <Object>[];
      final void Function() resume = _pausedListener(
        probe.stream.buffer(0, onBufferOverflow: BufferOverflow.dropLatest),
        events,
      );
      await settle();

      await probe.emitAll(<int>[1, 2]);
      resume();
      await settle();

      expect(events, <Object>[1, 'done']);
    });

    test('keeps the latest element with conflate', () async {
      final probe = ProbeStream<int>();
      final events = <Object>[];
      final void Function() resume = _pausedListener(
        probe.stream.conflate(),
        events,
      );
      await settle();

      await probe.emitAll(<int>[1, 2, 3]);
      resume();
      await settle();

      expect(events, <Object>[3, 'done']);
    });
  });

  group('errors and cancel', () {
    test('keeps errors in place and never drops them', () async {
      final probe = ProbeStream<int>();
      final events = <Object>[];
      final void Function() resume = _pausedListener(
        probe.stream.buffer(1, onBufferOverflow: BufferOverflow.dropOldest),
        events,
      );
      await settle();

      probe.controller
        ..add(1)
        ..addError(const FormatException())
        ..add(2);
      await probe.emitAll(<int>[]);
      resume();
      await settle();

      expect(events, <Object>[isFormatException, 2, 'done']);
    });

    test('cancels the stream when the listener cancels', () async {
      final probe = ProbeStream<int>();
      final StreamSubscription<int> subscription = probe.stream
          .buffer(4)
          .listen(null);
      await settle();

      await subscription.cancel();

      expect(probe.log, <String>['listen', 'cancel']);
    });
  });
}
