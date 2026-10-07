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

/// Runs a mix of microtasks, zero delay timers and futures, logging into
/// [log], and calls [done] once the last of them ran.
void _scenario(List<String> log, void Function() done) {
  log.add('sync');
  scheduleMicrotask(() {
    log.add('microtask 1');
    scheduleMicrotask(() => log.add('microtask 1.1'));
    Timer.run(() => log.add('timer from microtask 1'));
  });
  Timer.run(() {
    log.add('timer 1');
    scheduleMicrotask(() => log.add('microtask from timer 1'));
  });
  unawaited(Future<void>(() => log.add('future')));
  unawaited(Future<void>.microtask(() => log.add('future.microtask')));
  unawaited(Future<void>.delayed(Duration.zero, () => log.add('delayed')));
  Timer(Duration.zero, () {
    log.add('timer 2');
    unawaited(Future<void>.value().then((_) => log.add('then in timer 2')));
    scheduleMicrotask(() => log.add('microtask in timer 2'));
  });
  final completer = Completer<void>();
  unawaited(completer.future.then((_) => log.add('completer')));
  completer.complete();
  unawaited(Future<int>.value(1).then((value) => log.add('value $value')));
  scheduleMicrotask(() => log.add('microtask 2'));
  Timer.run(() {
    log.add('timer 3');
    Timer.run(() {
      log.add('last');
      done();
    });
  });
  log.add('sync end');
}

/// Covers that the virtual event loop of a `TestScheduler` orders
/// microtasks and timers exactly as the real event loop does.
void main() {
  test('orders microtasks before timers exactly as the real loop', () async {
    final real = <String>[];
    final realDone = Completer<void>();
    _scenario(real, realDone.complete);
    await realDone.future;

    final virtual = <String>[];
    final scheduler = TestScheduler();
    var virtualDone = false;
    scheduler.run(() {
      _scenario(virtual, () => virtualDone = true);
      unawaited(scheduler.advanceUntilIdle());
    });

    expect(virtualDone, isTrue);
    expect(virtual, real);
    expect(real.first, 'sync');
    expect(real.last, 'last');
  });

  test('orders them the same way inside runTest', () async {
    final real = <String>[];
    final realDone = Completer<void>();
    _scenario(real, realDone.complete);
    await realDone.future;

    final virtual = <String>[];
    await runTest((it) async {
      final done = Completer<void>();
      _scenario(virtual, done.complete);
      await done.future;
    });

    expect(virtual, real);
  });

  test('runs timers in due order with the microtasks of each first', () {
    final scheduler = TestScheduler();
    final log = <String>[];

    scheduler.run(() {
      Timer(2.milliseconds, () {
        log.add('2 ms');
        scheduleMicrotask(() => log.add('microtask of 2 ms'));
      });
      Timer(1.milliseconds, () {
        log.add('1 ms');
        scheduleMicrotask(() => log.add('microtask of 1 ms'));
        Timer(Duration.zero, () => log.add('zero from 1 ms'));
      });
      Timer(1.milliseconds, () => log.add('1 ms, second'));
      unawaited(scheduler.advanceUntilIdle());
    });

    expect(log, <String>[
      '1 ms',
      'microtask of 1 ms',
      '1 ms, second',
      'zero from 1 ms',
      '2 ms',
      'microtask of 2 ms',
    ]);
  });
}
