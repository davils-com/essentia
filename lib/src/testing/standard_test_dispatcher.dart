/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/coroutines/coroutine_context.dart';
import 'package:essentia/src/coroutines/coroutine_dispatcher.dart';
import 'package:essentia/src/coroutines/parallelism.dart';
import 'package:essentia/src/testing/test_dispatcher.dart';
import 'package:essentia/src/testing/test_scheduler.dart';

/// The dispatcher of `runTest`, Kotlin's `StandardTestDispatcher`.
///
/// A body it dispatches is queued as a task due now on the virtual time of
/// its [scheduler]; it runs once the test waits, or on `runCurrent`.
final class StandardTestDispatcher extends TestDispatcher {
  /// Creates the dispatcher on [scheduler], a new one unless given, named
  /// [name] for diagnostics.
  StandardTestDispatcher({TestScheduler? scheduler, this.name})
    : scheduler = scheduler ?? TestScheduler();

  /// The scheduler whose virtual time the dispatcher runs on.
  @override
  final TestScheduler scheduler;

  /// The name of the dispatcher, if it has one.
  final String? name;

  /// Queues [block] as a task due now, in [zone].
  @override
  void dispatch(CoroutineContext context, Zone zone, void Function() block) =>
      zone.run(() => scheduler.schedule(Duration.zero, block));

  /// A dispatcher on the same virtual time; the test runs one body at a
  /// time anyway.
  ///
  /// Returns the view.
  ///
  /// Throws a [RangeError] if [parallelism] is smaller than one.
  @override
  CoroutineDispatcher limitedParallelism(int parallelism) {
    checkParallelism(parallelism);
    return StandardTestDispatcher(scheduler: scheduler, name: name);
  }

  /// Names the dispatcher.
  @override
  String toString() => 'StandardTestDispatcher[${name ?? scheduler}]';
}
