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

import 'commanded_sharing.dart';

/// A re-listenable stream that counts up from zero every 100 milliseconds
/// for every listener, recording `listen` and `cancel` in [log].
///
/// Returns the stream.
Stream<int> _ticks(List<String> log) => Stream<int>.multi((controller) {
  log.add('listen');
  var next = 0;
  final timer = Timer.periodic(
    const Duration(milliseconds: 100),
    (_) => controller.add(next++),
  );
  controller.onCancel = () {
    log.add('cancel');
    timer.cancel();
  };
});

/// A scope on the virtual time of [test] whose failures go to [failures]
/// instead of failing the test.
///
/// Returns the scope.
CoroutineScope _isolatedScope(TestScope test, List<Object> failures) =>
    CoroutineScope(
      test.coroutineContext +
          Job() +
          CoroutineExceptionHandler(
            (context, error, stackTrace) => failures.add(error),
          ),
    );

/// Shorthand for a number of milliseconds.
///
/// Returns the duration.
Duration _ms(int milliseconds) => Duration(milliseconds: milliseconds);

/// Covers `shareIn`, `stateIn` and `awaitStateIn` with every sharing
/// strategy, on virtual time.
void main() {
  group('shareIn', () {
    test(
      'shares eagerly without waiting for a listener',
      () => runTest((it) {
        final log = <String>[];
        final SharedFlow<int> shared = _ticks(log)
            .shareIn(it.backgroundScope, SharingStarted.eagerly, replay: 1);
        final before = List<String>.of(log);

        it.advanceTimeBy(_ms(250));

        expect(before, isEmpty);
        expect(log, <String>['listen']);
        expect(shared.replayCache, <int>[1]);
        expect(shared, isNot(isA<MutableSharedFlow<int>>()));
      }),
    );

    test(
      'shares lazily from the first listener on, for good',
      () => runTest((it) async {
        final log = <String>[];
        final SharedFlow<int> shared = _ticks(log)
            .shareIn(it.backgroundScope, SharingStarted.lazily);
        it.advanceTimeBy(_ms(500));
        final before = List<String>.of(log);

        final values = <int>[];
        final Job collecting = it.launch((_) => shared.collect(values.add));
        it.advanceTimeBy(_ms(250));
        await collecting.cancelAndJoin();
        it.advanceTimeBy(_ms(1000));

        expect(before, isEmpty);
        expect(values, <int>[0, 1]);
        expect(log, <String>['listen']);
      }),
    );

    test(
      'stops the stop timeout after the last listener left',
      () => runTest((it) async {
        final log = <String>[];
        final SharedFlow<int> shared = _ticks(log).shareIn(
          it.backgroundScope,
          SharingStarted.whileSubscribed(stopTimeout: _ms(1000)),
          replay: 1,
        );
        it.runCurrent();
        final before = List<String>.of(log);

        final Job first = it.launch((_) => shared.collect());
        it.advanceTimeBy(_ms(250));
        await first.cancelAndJoin();
        it.advanceTimeBy(_ms(999));
        final beforeTimeout = List<String>.of(log);
        it.advanceTimeBy(_ms(1));
        final afterTimeout = List<String>.of(log);

        final values = <int>[];
        final Job second = it.launch((_) => shared.collect(values.add));
        it.advanceTimeBy(_ms(150));
        await second.cancelAndJoin();

        expect(before, isEmpty);
        expect(beforeTimeout, <String>['listen']);
        expect(afterTimeout, <String>['listen', 'cancel']);
        expect(log, <String>['listen', 'cancel', 'listen']);
        expect(values, <int>[11, 0]);
      }),
    );

    test(
      'keeps sharing when a listener comes back within the timeout',
      () => runTest((it) async {
        final log = <String>[];
        final SharedFlow<int> shared = _ticks(log).shareIn(
          it.backgroundScope,
          SharingStarted.whileSubscribed(stopTimeout: _ms(1000)),
        );

        final Job first = it.launch((_) => shared.collect());
        it.advanceTimeBy(_ms(250));
        await first.cancelAndJoin();
        it.advanceTimeBy(_ms(500));
        final Job second = it.launch((_) => shared.collect());
        it.advanceTimeBy(_ms(2000));
        await second.cancelAndJoin();

        expect(log, <String>['listen']);
      }),
    );

    test(
      'forgets the replay values once they expired',
      () => runTest((it) async {
        final log = <String>[];
        final SharedFlow<int> shared = _ticks(log).shareIn(
          it.backgroundScope,
          SharingStarted.whileSubscribed(replayExpiration: _ms(500)),
          replay: 1,
        );

        final Job collecting = it.launch((_) => shared.collect());
        it.advanceTimeBy(_ms(250));
        await collecting.cancelAndJoin();
        it.advanceTimeBy(_ms(499));
        final List<int> beforeExpiry = shared.replayCache;
        it.advanceTimeBy(_ms(1));

        expect(log, <String>['listen', 'cancel']);
        expect(beforeExpiry, <int>[1]);
        expect(shared.replayCache, isEmpty);
      }),
    );

    test(
      'follows the commands of a strategy of its own',
      () => runTest((it) {
        final log = <String>[];
        final commands = StreamController<SharingCommand>();
        addTearDown(commands.close);
        final SharedFlow<int> shared = _ticks(log)
            .shareIn(it.backgroundScope, CommandedSharing(commands), replay: 1);

        commands.add(SharingCommand.start);
        it.advanceTimeBy(_ms(150));
        commands
          ..add(SharingCommand.start)
          ..add(SharingCommand.stop);
        it.advanceTimeBy(_ms(150));
        final List<int> afterStop = shared.replayCache;
        commands.add(SharingCommand.stopAndResetReplayCache);
        it.runCurrent();

        expect(log, <String>['listen', 'cancel']);
        expect(afterStop, <int>[0]);
        expect(shared.replayCache, isEmpty);
      }),
    );

    test(
      'fails the sharing coroutine when the upstream stream fails',
      () => runTest((it) {
        final failures = <Object>[];
        final CoroutineScope scope = _isolatedScope(it, failures);
        final upstream = StreamController<int>();
        addTearDown(upstream.close);

        upstream.stream.shareIn(scope, SharingStarted.eagerly);
        it.runCurrent();
        upstream.addError(const FormatException('broken'));
        it.runCurrent();

        expect(failures.single, isFormatException);
      }),
    );

    test(
      'fails visibly when a single subscription upstream restarts',
      () => runTest((it) async {
        final failures = <Object>[];
        final CoroutineScope scope = _isolatedScope(it, failures);
        final upstream = StreamController<int>();
        addTearDown(upstream.close);
        final SharedFlow<int> shared = upstream.stream.shareIn(
          scope,
          SharingStarted.whileSubscribed(),
        );

        final Job first = it.launch((_) => shared.collect());
        it.runCurrent();
        await first.cancelAndJoin();
        it.runCurrent();
        final Job second = it.launch((_) => shared.collect());
        it.runCurrent();
        await second.cancelAndJoin();

        expect(failures.single, isStateError);
      }),
    );

    test(
      'refuses a negative replay',
      () => runTest((it) {
        expect(
          () => const Stream<int>.empty().shareIn(
            it.backgroundScope,
            SharingStarted.eagerly,
            replay: -1,
          ),
          throwsArgumentError,
        );
      }),
    );
  });

  group('stateIn', () {
    test(
      'starts with the initial value and follows the upstream',
      () => runTest((it) {
        final log = <String>[];
        final StateFlow<int> state = _ticks(log)
            .stateIn(it.backgroundScope, SharingStarted.eagerly, -1);
        final int initial = state.value;

        it.advanceTimeBy(_ms(250));

        expect(initial, -1);
        expect(state.value, 1);
        expect(state, isNot(isA<MutableStateFlow<int>>()));
      }),
    );

    test(
      'goes back to the initial value when the strategy resets',
      () => runTest((it) async {
        final log = <String>[];
        final StateFlow<int> state = _ticks(log).stateIn(
          it.backgroundScope,
          SharingStarted.whileSubscribed(replayExpiration: Duration.zero),
          -1,
        );

        final values = <int>[];
        final Job collecting = it.launch((_) => state.collect(values.add));
        it.advanceTimeBy(_ms(250));
        final int during = state.value;
        await collecting.cancelAndJoin();
        it.runCurrent();

        expect(values, <int>[-1, 0, 1]);
        expect(during, 1);
        expect(state.value, -1);
        expect(log, <String>['listen', 'cancel']);
      }),
    );
  });

  group('awaitStateIn', () {
    test(
      'completes with the first value of the upstream',
      () => runTest((it) async {
        final log = <String>[];

        final StateFlow<int> state = await _ticks(log)
            .awaitStateIn(it.backgroundScope);
        final Duration at = it.currentTime;
        final int first = state.value;
        it.advanceTimeBy(_ms(100));

        expect(at, _ms(100));
        expect(first, 0);
        expect(state.value, 1);
      }),
    );

    test(
      'keeps the last value once the upstream ended',
      () => runTest((it) async {
        final StateFlow<int> state = await Stream<int>.fromIterable(<int>[1, 2])
            .awaitStateIn(it.backgroundScope);
        it.runCurrent();

        expect(state.value, 2);
      }),
    );

    test(
      'fails when the upstream ends without a value',
      () => runTest((it) async {
        await expectLater(
          const Stream<int>.empty().awaitStateIn(it.backgroundScope),
          throwsStateError,
        );
      }),
    );

    test(
      'fails with the error of the upstream',
      () => runTest((it) async {
        final failures = <Object>[];
        final CoroutineScope scope = _isolatedScope(it, failures);

        await expectLater(
          Stream<int>.error(const FormatException()).awaitStateIn(scope),
          throwsFormatException,
        );
        expect(failures.single, isFormatException);
      }),
    );
  });
}
