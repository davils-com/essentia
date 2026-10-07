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

/// Covers the dispatchers: the event loop, unconfined starts, limited
/// parallelism, and the dispatchers of a test.
void main() {
  group('Dispatchers.main', () {
    test('starts a body in a microtask, before any timer', () async {
      final log = <String>[];
      final scope = CoroutineScope(Dispatchers.main);
      Timer.run(() => log.add('timer'));

      final Job job = scope.launch((it) => log.add('body'));
      log.add('launched');
      await job.join();
      await Future<void>.delayed(Duration.zero);

      expect(log, <String>['launched', 'body', 'timer']);
    });

    test('is the dispatcher of a context without one', () async {
      final log = <String>[];

      final Job job = CoroutineScope(Job()).launch((it) => log.add('body'));
      log.add('launched');
      await job.join();

      expect(log, <String>['launched', 'body']);
    });

    test('is its own limited view', () {
      expect(Dispatchers.main.limitedParallelism(1), same(Dispatchers.main));
      expect(Dispatchers.main.limitedParallelism(8), same(Dispatchers.main));
      expect(() => Dispatchers.main.limitedParallelism(0), throwsRangeError);
    });

    test('needs to dispatch and names itself', () {
      expect(Dispatchers.main.isDispatchNeeded(CoroutineContext.empty), isTrue);
      expect(Dispatchers.main.toString(), 'Dispatchers.main');
      expect(Dispatchers.main.contextKey, same(CoroutineDispatcher.key));
    });
  });

  group('Dispatchers.unconfined', () {
    test("starts a body at once in the caller's frame", () async {
      final log = <String>[];
      final scope = CoroutineScope(Dispatchers.unconfined);

      final Job job = scope.launch((it) async {
        log.add('body');
        await Future<void>.delayed(Duration.zero);
        log.add('resumed');
      });
      log.add('launched');
      await job.join();

      expect(log, <String>['body', 'launched', 'resumed']);
    });

    test('runs a dispatched block at once in the zone', () {
      final log = <String>[];
      final Zone zone = Zone.current.fork(
        zoneValues: <Object?, Object?>{#marker: 'marked'},
      );

      Dispatchers.unconfined.dispatch(
        CoroutineContext.empty,
        zone,
        () => log.add('${Zone.current[#marker]}'),
      );

      expect(log, <String>['marked']);
    });

    test('has no limited view', () {
      expect(
        () => Dispatchers.unconfined.limitedParallelism(1),
        throwsUnsupportedError,
      );
    });

    test('never needs to dispatch and names itself', () {
      expect(
        Dispatchers.unconfined.isDispatchNeeded(CoroutineContext.empty),
        isFalse,
      );
      expect(Dispatchers.unconfined.toString(), 'Dispatchers.unconfined');
    });
  });

  group('StandardTestDispatcher', () {
    test('queues a body as a task due now', () {
      final scheduler = TestScheduler();
      final dispatcher = StandardTestDispatcher(scheduler: scheduler);
      final log = <String>[];

      scheduler.run(
        () => CoroutineScope(dispatcher).launch((it) => log.add('body')),
      );
      final int pending = scheduler.pendingTasks;
      scheduler.run(() => unawaited(scheduler.runCurrent()));

      expect(pending, 1);
      expect(log, <String>['body']);
      expect(scheduler.currentTime, Duration.zero);
    });

    test('creates a scheduler of its own unless given one', () {
      final dispatcher = StandardTestDispatcher(name: 'own');

      expect(dispatcher.scheduler, isA<TestScheduler>());
      expect(dispatcher.toString(), 'StandardTestDispatcher[own]');
      expect(
        StandardTestDispatcher(scheduler: dispatcher.scheduler).toString(),
        'StandardTestDispatcher[TestScheduler(0:00:00.000000)]',
      );
    });

    test('has a limited view on the same scheduler', () {
      final dispatcher = StandardTestDispatcher(name: 'a');

      final CoroutineDispatcher view = dispatcher.limitedParallelism(2);

      expect(view, isA<StandardTestDispatcher>());
      expect(
        (view as StandardTestDispatcher).scheduler,
        same(dispatcher.scheduler),
      );
      expect(view.name, 'a');
      expect(() => dispatcher.limitedParallelism(0), throwsRangeError);
    });

    test(
      'is the dispatcher of runTest',
      () => runTest((it) {
        final CoroutineDispatcher? dispatcher = it.coroutineContext.get(
          CoroutineDispatcher.key,
        );

        expect(dispatcher, isA<StandardTestDispatcher>());
        expect(
          (dispatcher! as TestDispatcher).scheduler,
          same(it.testScheduler),
        );
      }),
    );
  });

  group('UnconfinedTestDispatcher', () {
    test(
      'starts a body at once',
      () => runTest((it) {
        final log = <String>[];

        it.launch(
          (it) => log.add('body'),
          context: UnconfinedTestDispatcher(scheduler: it.testScheduler),
        );
        log.add('launched');

        expect(log, <String>['body', 'launched']);
      }),
    );

    test('runs a dispatched block at once', () {
      final log = <String>[];

      UnconfinedTestDispatcher().dispatch(
        CoroutineContext.empty,
        Zone.current,
        () => log.add('ran'),
      );

      expect(log, <String>['ran']);
    });

    test('has a limited view on the same scheduler and names itself', () {
      final dispatcher = UnconfinedTestDispatcher(name: 'u');

      final CoroutineDispatcher view = dispatcher.limitedParallelism(3);

      expect(view, isA<UnconfinedTestDispatcher>());
      expect(
        (view as UnconfinedTestDispatcher).scheduler,
        same(dispatcher.scheduler),
      );
      expect(view.toString(), 'UnconfinedTestDispatcher[u]');
      expect(
        UnconfinedTestDispatcher(scheduler: dispatcher.scheduler).toString(),
        'UnconfinedTestDispatcher[TestScheduler(0:00:00.000000)]',
      );
      expect(dispatcher.isDispatchNeeded(CoroutineContext.empty), isFalse);
      expect(() => dispatcher.limitedParallelism(0), throwsRangeError);
    });

    test('lends its scheduler to runTest', () {
      final dispatcher = UnconfinedTestDispatcher();

      return runTest((it) {
        expect(it.testScheduler, same(dispatcher.scheduler));
      }, context: dispatcher);
    });
  });
}
