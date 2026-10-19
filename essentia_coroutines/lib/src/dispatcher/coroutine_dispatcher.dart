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

import 'package:essentia_coroutines/src/context/abstract_coroutine_context_element.dart';
import 'package:essentia_coroutines/src/context/coroutine_context.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_key.dart';

/// Decides where the body of a coroutine starts.
///
/// An isolate runs one thing at a time, so a dispatcher decides only how a
/// body is started: on the event loop, at once, or on another isolate. The
/// code after each `await` goes on in the zone of the coroutine on the
/// event loop of its isolate.
abstract class CoroutineDispatcher with AbstractCoroutineContextElement {
  /// Creates a dispatcher.
  const CoroutineDispatcher();

  /// The key a dispatcher is stored under in a coroutine context.
  static const key = CoroutineContextKey<CoroutineDispatcher>(
    'CoroutineDispatcher',
  );

  /// The key a dispatcher is stored under.
  @override
  CoroutineContextKey<CoroutineDispatcher> get contextKey => key;

  /// Whether a body started with [context] has to be dispatched, or may start
  /// at once in the caller's frame.
  bool isDispatchNeeded(CoroutineContext context) => true;

  /// Runs [block] in [zone] later.
  void dispatch(CoroutineContext context, Zone zone, void Function() block);

  /// A view of this dispatcher that runs at most [parallelism] bodies at once.
  ///
  /// An isolate already runs one thing at a time, so a dispatcher of the
  /// event loop is its own view.
  ///
  /// Returns the limited dispatcher.
  ///
  /// Throws a [RangeError] if [parallelism] is smaller than one.
  CoroutineDispatcher limitedParallelism(int parallelism);
}
