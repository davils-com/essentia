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
import 'package:meta/meta.dart';

/// The dispatcher behind `Dispatchers.unconfined`: the body starts at once,
/// in the caller's frame.
@internal
final class UnconfinedDispatcher extends CoroutineDispatcher {
  /// Creates the dispatcher; there is one, `Dispatchers.unconfined`.
  const UnconfinedDispatcher();

  /// A body never has to be dispatched.
  ///
  /// Returns `false`.
  @override
  bool isDispatchNeeded(CoroutineContext context) => false;

  /// Runs [block] in [zone] at once.
  @override
  void dispatch(CoroutineContext context, Zone zone, void Function() block) =>
      zone.run(block);

  /// A body started at once is not limited by anything.
  ///
  /// Throws an [UnsupportedError].
  @override
  CoroutineDispatcher limitedParallelism(int parallelism) =>
      throw UnsupportedError(
        'limitedParallelism is not supported for Dispatchers.unconfined',
      );

  /// Names the dispatcher.
  @override
  String toString() => 'Dispatchers.unconfined';
}
