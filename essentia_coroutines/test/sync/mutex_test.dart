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

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_coroutines/testing.dart';
import 'package:test/test.dart';

/// Lets every pending microtask and zero delay timer run.
///
/// Returns a future that completes after them.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

/// Covers the mutex: one holder at a time, fair waiting and cancellation.
void main() {
  test('starts unlocked unless told otherwise', () {
    expect(Mutex().isLocked, isFalse);
    expect(Mutex(locked: true).isLocked, isTrue);
    expect(Mutex().toString(), 'Mutex(unlocked)');
    expect(Mutex(locked: true).toString(), 'Mutex(locked)');
  });

  test('takes a free lock without waiting, and only once', () {
    final mutex = Mutex();

    expect(mutex.tryLock(), isTrue);
    expect(mutex.tryLock(), isFalse);
    expect(mutex.isLocked, isTrue);
  });

  test('refuses to unlock a lock nobody holds', () {
    expect(Mutex().unlock, throwsStateError);
  });

  test('keeps asynchronous sections apart', () async {
    final mutex = Mutex();
    final log = <String>[];
    Future<void> section(String name) => mutex.withLock(() async {
      log.add('$name in');
      await _settle();
      log.add('$name out');
    });

    await Future.wait(<Future<void>>[section('a'), section('b')]);

    expect(log, <String>['a in', 'a out', 'b in', 'b out']);
    expect(mutex.isLocked, isFalse);
  });

  test('hands the lock to the waiter when it is given back', () async {
    final mutex = Mutex()..tryLock();
    var locked = false;
    unawaited(mutex.lock().then((_) => locked = true));
    await _settle();

    mutex.unlock();
    await _settle();

    expect(locked, isTrue);
    expect(mutex.isLocked, isTrue);
  });

  test(
    'serves waiters oldest first',
    () => runTest((it) {
      final mutex = Mutex();
      final log = <int>[];
      for (var index = 0; index < 3; index++) {
        it.launch((it) async {
          await mutex.withLock(() async {
            log.add(index);
            await delay(1.seconds);
          });
        });
      }

      it.advanceUntilIdle();

      expect(log, <int>[0, 1, 2]);
      expect(it.currentTime, 3.seconds);
    }),
  );

  test('gives the lock back when the section fails', () async {
    final mutex = Mutex();

    final Future<void> failed = mutex.withLock(
      () => throw const FormatException(),
    );

    await expectLater(failed, throwsFormatException);
    expect(mutex.isLocked, isFalse);
  });

  test(
    'stops a waiter whose job is cancelled',
    () => runTest((it) async {
      final mutex = Mutex()..tryLock();
      final Deferred<void> locking = it.async((it) => mutex.lock());
      it.runCurrent();

      locking.cancel();

      await expectLater(locking, throwsA(isA<CancellationException>()));
      expect(mutex.isLocked, isTrue);
    }),
  );

  test(
    'is a cancellation checkpoint for a section that waits',
    () => runTest((it) async {
      final mutex = Mutex();
      final log = <String>[];
      final Job holder = it.launch(
        (it) => mutex.withLock(() async {
          try {
            await delay(1.hours);
          } finally {
            log.add('released');
          }
        }),
      );
      final Job waiter = it.launch(
        (it) => mutex.withLock(() => log.add('never')),
      );
      it.runCurrent();

      waiter.cancel();
      await holder.cancelAndJoin();

      expect(log, <String>['released']);
      expect(mutex.isLocked, isFalse);
    }),
  );
}
