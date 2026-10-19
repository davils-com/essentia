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
import 'package:essentia_coroutines/testing.dart';
import 'package:test/test.dart';

/// Shorthand for a number of milliseconds.
///
/// Returns the duration.
Duration _ms(int milliseconds) => Duration(milliseconds: milliseconds);

/// Covers the `SharingStarted` strategies: their commands on virtual time,
/// their validation, equality and names.
void main() {
  group('eagerly', () {
    test('starts at once', () async {
      final MutableStateFlow<int> count = MutableStateFlow(0);

      final List<SharingCommand> commands = await SharingStarted.eagerly
          .command(count)
          .toList();

      expect(commands, <SharingCommand>[SharingCommand.start]);
      expect(SharingStarted.eagerly.toString(), 'SharingStarted.eagerly');
    });
  });

  group('lazily', () {
    test(
      'starts with the first listener and then ends',
      () => runTest((it) async {
        final MutableStateFlow<int> count = MutableStateFlow(0);
        final Future<List<SharingCommand>> commands = SharingStarted.lazily
            .command(count)
            .toList();
        it.runCurrent();

        count.value = 1;
        it.runCurrent();
        count.value = 0;

        expect(await commands, <SharingCommand>[SharingCommand.start]);
        expect(SharingStarted.lazily.toString(), 'SharingStarted.lazily');
      }),
    );
  });

  group('whileSubscribed', () {
    test(
      'stops after the timeout and resets after the expiration',
      () => runTest((it) {
        final MutableStateFlow<int> count = MutableStateFlow(0);
        final log = <String>[];
        it.backgroundScope.launch(
          (_) =>
              SharingStarted.whileSubscribed(
                    stopTimeout: _ms(100),
                    replayExpiration: _ms(200),
                  )
                  .command(count)
                  .collect(
                    (command) =>
                        log.add('${command.name} at ${it.currentTime}'),
                  ),
        );
        it.advanceTimeBy(_ms(1000));

        count.value = 1;
        it.advanceTimeBy(_ms(50));
        count.value = 0;
        it.advanceTimeBy(_ms(500));

        expect(log, <String>[
          'start at ${_ms(1000)}',
          'stop at ${_ms(1150)}',
          'stopAndResetReplayCache at ${_ms(1350)}',
        ]);
      }),
    );

    test(
      'keeps going when a listener comes back within the timeout',
      () => runTest((it) {
        final MutableStateFlow<int> count = MutableStateFlow(1);
        final log = <SharingCommand>[];
        it.backgroundScope.launch(
          (_) =>
              SharingStarted.whileSubscribed(stopTimeout: _ms(100))
                  .command(count)
                  .collect(log.add),
        );
        it.runCurrent();

        count.value = 0;
        it.advanceTimeBy(_ms(99));
        count.value = 2;
        it.advanceTimeBy(_ms(1000));

        expect(log, <SharingCommand>[SharingCommand.start]);
      }),
    );

    test(
      'never resets without an expiration',
      () => runTest((it) {
        final MutableStateFlow<int> count = MutableStateFlow(1);
        final log = <SharingCommand>[];
        it.backgroundScope.launch(
          (_) =>
              SharingStarted.whileSubscribed().command(count).collect(log.add),
        );
        it.runCurrent();

        count.value = 0;
        it.advanceTimeBy(const Duration(days: 365));

        expect(log, <SharingCommand>[
          SharingCommand.start,
          SharingCommand.stop,
        ]);
      }),
    );

    test(
      'resets at once with a zero expiration',
      () => runTest((it) {
        final MutableStateFlow<int> count = MutableStateFlow(1);
        final log = <SharingCommand>[];
        it.backgroundScope.launch(
          (_) =>
              SharingStarted.whileSubscribed(replayExpiration: Duration.zero)
                  .command(count)
                  .collect(log.add),
        );
        it.runCurrent();

        count.value = 0;
        it.runCurrent();

        expect(log, <SharingCommand>[
          SharingCommand.start,
          SharingCommand.stopAndResetReplayCache,
        ]);
      }),
    );

    test(
      'says nothing before the first listener',
      () => runTest((it) {
        final MutableStateFlow<int> count = MutableStateFlow(0);
        final log = <SharingCommand>[];
        it.backgroundScope.launch(
          (_) =>
              SharingStarted.whileSubscribed(replayExpiration: Duration.zero)
                  .command(count)
                  .collect(log.add),
        );

        it.advanceTimeBy(_ms(1000));

        expect(log, isEmpty);
      }),
    );

    test('refuses a negative stop timeout', () {
      expect(
        () => SharingStarted.whileSubscribed(stopTimeout: _ms(-1)),
        throwsA(
          isArgumentError.having(
            (error) => error.message,
            'message',
            'stopTimeout(${_ms(-1)}) cannot be negative',
          ),
        ),
      );
    });

    test('refuses a negative replay expiration', () {
      expect(
        () => SharingStarted.whileSubscribed(replayExpiration: _ms(-1)),
        throwsA(
          isArgumentError.having(
            (error) => error.message,
            'message',
            'replayExpiration(${_ms(-1)}) cannot be negative',
          ),
        ),
      );
    });

    test('equals a strategy with the same timing', () {
      final SharingStarted strategy = SharingStarted.whileSubscribed(
        stopTimeout: _ms(5),
      );
      final SharingStarted same = SharingStarted.whileSubscribed(
        stopTimeout: _ms(5),
      );
      final SharingStarted other = SharingStarted.whileSubscribed(
        stopTimeout: _ms(5),
        replayExpiration: _ms(1),
      );

      expect(strategy, same);
      expect(strategy.hashCode, same.hashCode);
      expect(strategy, isNot(other));
      expect(strategy, isNot(SharingStarted.eagerly));
    });

    test('names itself with its timing', () {
      expect(
        SharingStarted.whileSubscribed(stopTimeout: _ms(5)).toString(),
        'SharingStarted.whileSubscribed(stopTimeout: ${_ms(5)})',
      );
      expect(
        SharingStarted.whileSubscribed(replayExpiration: _ms(1)).toString(),
        'SharingStarted.whileSubscribed(stopTimeout: ${Duration.zero}, '
        'replayExpiration: ${_ms(1)})',
      );
    });
  });
}
