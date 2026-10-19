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
import 'package:essentia_coroutines/src/dispatcher/dispatchers.dart';
import 'package:essentia_coroutines/src/dispatcher/parallelism.dart';
import 'package:meta/meta.dart';

/// The dispatcher behind `Dispatchers.main`: a microtask on the event loop
/// of the isolate.
@internal
final class EventLoopDispatcher extends CoroutineDispatcher {
  /// Creates the dispatcher; there is one, `Dispatchers.main`.
  const EventLoopDispatcher();

  /// Runs [block] in a microtask of [zone].
  @override
  void dispatch(CoroutineContext context, Zone zone, void Function() block) =>
      zone.scheduleMicrotask(block);

  /// The event loop runs one body at a time anyway.
  ///
  /// Returns `Dispatchers.main`.
  ///
  /// Throws a [RangeError] if [parallelism] is smaller than one.
  @override
  CoroutineDispatcher limitedParallelism(int parallelism) {
    checkParallelism(parallelism);
    return Dispatchers.main;
  }

  /// Names the dispatcher.
  @override
  String toString() => 'Dispatchers.main';
}
