/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/src/context/coroutine_context.dart';
import 'package:essentia_coroutines/src/coroutine/coroutine_start.dart';
import 'package:essentia_coroutines/src/dispatcher/coroutine_dispatcher.dart';
import 'package:essentia_coroutines/src/exception/coroutine_exception_handler.dart';
import 'package:essentia_coroutines/src/exception/suppressed_exceptions.dart';
import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/job/supervisor_job.dart';
import 'package:essentia_coroutines/src/scheduler/scheduler.dart';
import 'package:essentia_coroutines/src/scope/coroutine_scope.dart';
import 'package:essentia_coroutines/src/testing/background_work.dart';
import 'package:essentia_coroutines/src/testing/standard_test_dispatcher.dart';
import 'package:essentia_coroutines/src/testing/test_dispatcher.dart';
import 'package:essentia_coroutines/src/testing/test_scheduler.dart';
import 'package:essentia_coroutines/src/testing/test_scope.dart';
import 'package:essentia_coroutines/src/testing/test_scope_impl.dart';
import 'package:essentia_coroutines/src/testing/uncompleted_coroutines_error.dart';

/// Runs [body] as a coroutine on virtual time and waits until it and every
/// coroutine it started completed.
///
/// Everything the body starts - coroutines, `Timer`s, `Future.delayed`,
/// `Scheduler.system` - runs on the virtual event loop of one
/// `TestScheduler`. Whenever the body waits and nothing else can run,
/// virtual time skips to the next timer, so a test of an hour of retries
/// takes no time at all.
///
/// [context] is laid over the context of the test; a `TestScheduler` or a
/// `TestDispatcher` in it is used instead of a new one. Work started in the
/// background scope of the test is cancelled once the body is done.
///
/// ```dart
/// test('polls every half minute', () => runTest((it) async {
///   final Job polling = it.backgroundScope.launch((it) => poll());
///   await delay(90.seconds);
///   expect(polls, 3);
/// }));
/// ```
///
/// Returns a future that completes once the test completed.
///
/// Throws the failure of the body or of a coroutine it started, and an
/// [UncompletedCoroutinesError] if the test does not complete within
/// [timeout] of real time.
Future<void> runTest(
  FutureOr<void> Function(TestScope it) body, {
  CoroutineContext context = CoroutineContext.empty,
  Duration timeout = const Duration(seconds: 60),
}) async {
  final CoroutineDispatcher? given = context.get(CoroutineDispatcher.key);
  final Scheduler? givenScheduler = context.get(Scheduler.key);
  final TestScheduler scheduler = _schedulerOf(given, givenScheduler);
  final failures = <AsyncError>[];
  final CoroutineContext testContext =
      scheduler +
      StandardTestDispatcher(scheduler: scheduler) +
      CoroutineExceptionHandler(
        (context, error, stackTrace) =>
            failures.add(AsyncError(error, stackTrace)),
      ) +
      context;
  final Job background = SupervisorJob();
  final TestScopeImpl scope = scheduler.run(
    () => TestScopeImpl(
      testContext.minusKey(Job.key),
      testScheduler: scheduler,
      backgroundScope: CoroutineScope(
        testContext + const BackgroundWork() + background,
      ),
    ),
  );
  await _drive(scheduler, scope, body, timeout);
  final bool timedOut = !scope.isCompleted;
  if (timedOut) {
    scope.cancel();
  }
  background.cancel();
  scheduler
    ..runCurrentSync()
    ..listenForWork(null);
  if (timedOut) {
    scheduler.dropTimers();
    throw UncompletedCoroutinesError(
      'After waiting for $timeout of real time, the test is not complete: '
      '$scope',
    );
  }
  scheduler.dropTimers();
  final AsyncError? failure = scope.completionError;
  if (failure != null) {
    for (final other in failures) {
      addSuppressed(failure.error, other.error);
    }
    Error.throwWithStackTrace(failure.error, failure.stackTrace);
  }
  if (failures.isNotEmpty) {
    final AsyncError first = failures.first;
    for (final AsyncError other in failures.skip(1)) {
      addSuppressed(first.error, other.error);
    }
    Error.throwWithStackTrace(first.error, first.stackTrace);
  }
}

/// The scheduler a test runs on: the one of a given test dispatcher, a
/// given test scheduler, or a new one.
///
/// Returns the scheduler.
TestScheduler _schedulerOf(CoroutineDispatcher? given, Scheduler? scheduler) {
  if (given is TestDispatcher) {
    return given.scheduler;
  }
  if (scheduler is TestScheduler) {
    return scheduler;
  }
  return TestScheduler();
}

/// Starts [body] in [scope] on the virtual event loop of [scheduler] and
/// runs that loop until the scope completed or [timeout] of real time
/// passed.
///
/// Before virtual time moves on to the next timer, the real event loop
/// gets a turn: a continuation of an `await` on a future that completed in
/// the root zone runs there, outside the virtual loop, and has to run
/// before time passes, exactly as it would on real time.
///
/// Returns a future that completes then.
Future<void> _drive(
  TestScheduler scheduler,
  TestScopeImpl scope,
  FutureOr<void> Function(TestScope it) body,
  Duration timeout,
) async {
  scheduler.run(
    () =>
        scope.startCoroutine(CoroutineStart.undispatched, (it) => body(scope)),
  );
  final watch = Stopwatch()..start();
  var steps = 0;
  while (!scope.isCompleted) {
    if (scheduler.hasMicrotasks) {
      scheduler.step();
      steps++;
      if (steps % _stepsPerYield == 0) {
        await Future<void>.delayed(Duration.zero);
        if (watch.elapsed >= timeout) {
          return;
        }
      }
      continue;
    }
    if (scheduler.hasTimers) {
      await Future<void>.delayed(Duration.zero);
      if (watch.elapsed >= timeout) {
        return;
      }
      if (scheduler.hasMicrotasks || scope.isCompleted) {
        continue;
      }
      scheduler.step();
      continue;
    }
    final Duration remaining = timeout - watch.elapsed;
    if (remaining <= Duration.zero) {
      return;
    }
    final wake = Completer<void>();
    void wakeUp() {
      if (!wake.isCompleted) {
        wake.complete();
      }
    }

    scheduler.listenForWork(wakeUp);
    final timer = Timer(remaining, wakeUp);
    final Disposable completion = scope.invokeOnCompletion((cause) => wakeUp());
    await wake.future;
    completion.dispose();
    timer.cancel();
    scheduler.listenForWork(null);
  }
}

/// How many steps of the virtual event loop run before the real one gets a
/// turn.
const _stepsPerYield = 1024;
