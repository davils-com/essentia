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

import 'package:essentia_coroutines/src/context/coroutine_context.dart';
import 'package:essentia_coroutines/src/dispatcher/coroutine_dispatcher.dart';
import 'package:essentia_coroutines/src/dispatcher/parallelism.dart';
import 'package:essentia_coroutines/src/testing/test_dispatcher.dart';
import 'package:essentia_coroutines/src/testing/test_scheduler.dart';

/// A test dispatcher that starts a body at once.
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
