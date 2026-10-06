/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/stream/stream_semaphore.dart';
import 'package:test/test.dart';

import 'probe_stream.dart';

/// Checks the semaphore that bounds `flatMapMerge`.
void main() {
  test('refuses fewer than one permit', () {
    expect(() => StreamSemaphore(0), throwsRangeError);
  });

  test('runs an action right away while a permit is free', () async {
    final semaphore = StreamSemaphore(1);

    final int result = await semaphore.withPermit(() async => 7);

    expect(result, 7);
    expect(semaphore.availablePermits, 1);
  });

  test('lets an action wait until a permit is given back', () async {
    final semaphore = StreamSemaphore(1);
    final holding = Completer<void>();
    final log = <String>[];
    final Future<void> first = semaphore.withPermit(() async {
      log.add('first');
      await holding.future;
    });
    final Future<void> second = semaphore.withPermit(() async {
      log.add('second');
    });
    await settle();

    final whileHeld = List<String>.of(log);
    final int waiting = semaphore.waitingCount;
    holding.complete();
    await Future.wait(<Future<void>>[first, second]);

    expect(whileHeld, <String>['first']);
    expect(waiting, 1);
    expect(log, <String>['first', 'second']);
  });

  test('admits waiting actions oldest first', () async {
    final semaphore = StreamSemaphore(1);
    final holding = Completer<void>();
    final log = <int>[];
    final Future<void> held = semaphore.withPermit(() => holding.future);
    final waiting = <Future<void>>[
      for (var index = 0; index < 3; index++)
        semaphore.withPermit(() async => log.add(index)),
    ];
    await settle();

    holding.complete();
    await Future.wait(<Future<void>>[held, ...waiting]);

    expect(log, <int>[0, 1, 2]);
  });

  test('gives the permit back when the action fails', () async {
    final semaphore = StreamSemaphore(1);

    final Future<void> failed = semaphore.withPermit(
      () => Future<void>.error(const FormatException()),
    );

    await expectLater(failed, throwsFormatException);
    expect(semaphore.availablePermits, 1);
  });

  test('runs up to its permits at once', () async {
    final semaphore = StreamSemaphore(2);
    final holding = Completer<void>();
    var running = 0;
    final actions = <Future<void>>[
      for (var index = 0; index < 3; index++)
        semaphore.withPermit(() async {
          running++;
          await holding.future;
        }),
    ];
    await settle();

    final runningAtOnce = running;
    holding.complete();
    await Future.wait(actions);

    expect(runningAtOnce, 2);
    expect(running, 3);
    expect(semaphore.availablePermits, 2);
  });
}
