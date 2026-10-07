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

/// A re-listenable stream that emits `1` and then fails with a
/// [FormatException] on its first [failures] listens, and emits `1` and
/// `2` afterwards, counting the listens in [listens].
///
/// Returns the stream.
Stream<int> _flaky(int failures, List<int> listens) =>
    Stream<int>.multi((controller) {
      listens.add(listens.length);
      controller.add(1);
      if (listens.length <= failures) {
        controller.addError(const FormatException('flaky'));
        return;
      }
      controller.add(2);
      unawaited(controller.close());
    });

/// Covers `retry`, `retryWhen` and `catchError`.
void main() {
  group('retry', () {
    test('listens again until the stream succeeds', () async {
      final listens = <int>[];

      final List<int> values = await _flaky(
        2,
        listens,
      ).retry(retries: 3).toList();

      expect(values, <int>[1, 1, 1, 2]);
      expect(listens, hasLength(3));
    });

    test('passes the error on once the retries are used up', () async {
      final listens = <int>[];

      await expectLater(
        _flaky(5, listens).retry(retries: 1),
        emitsInOrder(<Object>[1, 1, emitsError(isFormatException), emitsDone]),
      );
      expect(listens, hasLength(2));
    });

    test('passes the error on when the predicate refuses', () async {
      final listens = <int>[];

      await expectLater(
        _flaky(5, listens).retry(predicate: (cause) => cause is StateError),
        emitsInOrder(<Object>[1, emitsError(isFormatException), emitsDone]),
      );
    });

    test('retries without end unless told otherwise', () async {
      final listens = <int>[];

      expect(await _flaky(3, listens).retry().last, 2);
    });

    test('refuses retries that are not positive', () {
      expect(
        () => const Stream<int>.empty().retry(retries: 0),
        throwsA(
          isArgumentError.having(
            (error) => error.message,
            'message',
            'Expected positive amount of retries, but had 0',
          ),
        ),
      );
    });
  });

  group('retryWhen', () {
    test(
      'waits for a backoff on virtual time',
      () => runTest((it) async {
        final listens = <int>[];
        final attempts = <String>[];

        final List<int> values = await _flaky(2, listens).retryWhen((
          cause,
          attempt,
        ) async {
          attempts.add('$attempt at ${it.currentTime.inMilliseconds}');
          await delay(Duration(milliseconds: 100 * (attempt + 1)));
          return true;
        }).toList();

        expect(values, <int>[1, 1, 1, 2]);
        expect(attempts, <String>['0 at 0', '1 at 100']);
        expect(it.currentTime, const Duration(milliseconds: 300));
      }),
    );

    test('passes an error of the predicate on', () async {
      await expectLater(
        _flaky(
          1,
          <int>[],
        ).retryWhen((cause, attempt) => throw StateError('predicate')),
        emitsInOrder(<Object>[1, emitsError(isStateError), emitsDone]),
      );
    });

    test('never retries a cancellation', () async {
      var asked = false;

      await expectLater(
        Stream<int>.error(const CancellationException())
            .retryWhen((cause, attempt) {
              asked = true;
              return true;
            }),
        emitsInOrder(<Object>[
          emitsError(isA<CancellationException>()),
          emitsDone,
        ]),
      );
      expect(asked, isFalse);
    });

    test('fails visibly when a single subscription stream retries', () async {
      final controller = StreamController<int>()
        ..addError(const FormatException());
      addTearDown(controller.close);

      await expectLater(
        controller.stream.retryWhen((cause, attempt) => true),
        emitsInOrder(<Object>[emitsError(isStateError), emitsDone]),
      );
    });

    test('does not listen again once the listener left', () async {
      final listens = <int>[];
      final gate = Completer<bool>();
      final StreamSubscription<int> subscription = _flaky(
        5,
        listens,
      ).retryWhen((cause, attempt) => gate.future).listen(null);
      await settle();

      await subscription.cancel();
      gate.complete(true);
      await settle();

      expect(listens, hasLength(1));
    });

    test('passes pause, resume and cancel on', () async {
      final probe = ProbeStream<int>();

      final List<String> log = await lifecycleOf(
        probe,
        (source) => source.retryWhen((cause, attempt) => true),
      );

      expect(log, <String>['listen', 'pause', 'resume', 'cancel']);
    });

    test('pauses a stream it listens to again while paused', () async {
      final listens = <int>[];
      final gate = Completer<bool>();
      final values = <int>[];
      final StreamSubscription<int> subscription = _flaky(
        1,
        listens,
      ).retryWhen((cause, attempt) => gate.future).listen(values.add);
      addTearDown(subscription.cancel);
      await settle();

      subscription.pause();
      gate.complete(true);
      await settle();
      final whilePaused = List<int>.of(values);
      subscription.resume();
      await settle();

      expect(whilePaused, <int>[1]);
      expect(values, <int>[1, 1, 2]);
    });

    test('keeps a broadcast stream broadcast', () {
      final probe = ProbeStream<int>.broadcast();

      expect(
        probe.stream.retryWhen((cause, attempt) => false).isBroadcast,
        isTrue,
      );
    });
  });

  group('catchError', () {
    test('ends the stream with what the action emits', () async {
      final List<int> values = await _flaky(1, <int>[]).catchError((
        it,
        error,
        stackTrace,
      ) async {
        await it.emit(-1);
        await it.emit(-2);
      }).toList();

      expect(values, <int>[1, -1, -2]);
    });

    test('passes a stream without errors on unchanged', () async {
      final List<int> values = await Stream<int>.fromIterable(<int>[1, 2])
          .catchError((it, error, stackTrace) => it.emit(-1))
          .toList();

      expect(values, <int>[1, 2]);
    });

    test('passes an error of the action on', () async {
      await expectLater(
        _flaky(
          1,
          <int>[],
        ).catchError((it, error, stackTrace) => throw StateError('action')),
        emitsInOrder(<Object>[1, emitsError(isStateError), emitsDone]),
      );
    });

    test('passes a cancellation on without running the action', () async {
      var ran = false;

      await expectLater(
        Stream<int>.error(const CancellationException())
            .catchError((it, error, stackTrace) => ran = true),
        emitsInOrder(<Object>[
          emitsError(isA<CancellationException>()),
          emitsDone,
        ]),
      );
      expect(ran, isFalse);
    });

    test('waits in emit while the listener is paused', () async {
      final log = <String>[];
      final StreamSubscription<int> subscription =
          Stream<int>.error(const FormatException())
              .catchError((it, error, stackTrace) async {
                await it.emit(1);
                log.add('emitted 1');
                await it.emit(2);
                log.add('emitted 2');
              })
              .listen((value) => log.add('got $value'));
      addTearDown(subscription.cancel);
      subscription.pause();
      await settle();
      final whilePaused = List<String>.of(log);

      subscription.resume();
      await settle();

      expect(whilePaused, isEmpty);
      expect(log, <String>['got 1', 'emitted 1', 'got 2', 'emitted 2']);
    });

    test('fails an emit once the listener cancelled', () async {
      final failure = Completer<Object>();
      final StreamSubscription<int> subscription =
          Stream<int>.error(const FormatException())
              .catchError((it, error, stackTrace) async {
                await settle();
                try {
                  await it.emit(1);
                } on Object catch (emitError) {
                  failure.complete(emitError);
                }
              })
              .listen(null);
      await Future<void>.value();

      await subscription.cancel();

      expect(await failure.future, isA<CancellationException>());
    });

    test('passes pause, resume and cancel on', () async {
      final probe = ProbeStream<int>();

      final List<String> log = await lifecycleOf(
        probe,
        (source) => source.catchError((it, error, stackTrace) {}),
      );

      expect(log, <String>['listen', 'pause', 'resume', 'cancel']);
    });
  });
}
