/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/context/coroutine_context.dart';
import 'package:essentia_coroutines/src/dispatcher/coroutine_dispatcher.dart';
import 'package:essentia_coroutines/src/dispatcher/parallelism.dart';
import 'package:essentia_coroutines/src/testing/test_dispatcher.dart';
import 'package:essentia_coroutines/src/testing/test_scheduler.dart';

/// A test dispatcher that starts a body at once, Kotlin's
/// `UnconfinedTestDispatcher`.
///
/// It suits code under test that has to be subscribed or running before
/// the test goes on, such as a collector of a hot flow.
final class UnconfinedTestDispatcher extends TestDispatcher {
  /// Creates the dispatcher on [scheduler], a new one unless given, named
  /// [name] for diagnostics.
  UnconfinedTestDispatcher({TestScheduler? scheduler, this.name})
    : scheduler = scheduler ?? TestScheduler();

  /// The scheduler whose virtual time the dispatcher runs on.
  @override
  final TestScheduler scheduler;

  /// The name of the dispatcher, if it has one.
  final String? name;

  /// A body never has to be dispatched.
  ///
  /// Returns `false`.
  @override
  bool isDispatchNeeded(CoroutineContext context) => false;

  /// Runs [block] in [zone] at once.
  @override
  void dispatch(CoroutineContext context, Zone zone, void Function() block) =>
      zone.run(block);

  /// A dispatcher on the same virtual time; the test runs one body at a
  /// time anyway.
  ///
  /// Returns the view.
  ///
  /// Throws a [RangeError] if [parallelism] is smaller than one.
  @override
  CoroutineDispatcher limitedParallelism(int parallelism) {
    checkParallelism(parallelism);
    return UnconfinedTestDispatcher(scheduler: scheduler, name: name);
  }

  /// Names the dispatcher.
  @override
  String toString() => 'UnconfinedTestDispatcher[${name ?? scheduler}]';
}
