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
import 'package:essentia_coroutines/src/dispatcher/remote_dispatcher.dart';
import 'package:essentia_coroutines/src/isolate/isolate_platform_web.dart'
    if (dart.library.io) 'package:essentia_coroutines/src/isolate/isolate_platform_io.dart';
import 'package:essentia_coroutines/src/scope/coroutine_scope.dart';
import 'package:meta/meta.dart';

/// The dispatcher behind `Dispatchers.isolate`: on a native platform every
/// body runs on a worker isolate of a pool with one isolate per processor;
/// where there are no isolates, as on the web, it starts on the event loop.
@internal
final class IsolateDispatcher extends CoroutineDispatcher
    implements RemoteDispatcher {
  /// Creates the dispatcher; there is one, `Dispatchers.isolate`.
  const IsolateDispatcher();

  /// Whether bodies run on worker isolates.
  @override
  bool get remote => isolatesAvailable();

  /// Runs [block] in a microtask of [zone]; a body of a coroutine goes
  /// through [execute] where there are isolates.
  @override
  void dispatch(CoroutineContext context, Zone zone, void Function() block) =>
      zone.scheduleMicrotask(block);

  /// A view on the same pool that runs at most [parallelism] bodies at
  /// once, or this dispatcher where there are no isolates.
  ///
  /// Returns the view.
  ///
  /// Throws a [RangeError] if [parallelism] is smaller than one.
  @override
  CoroutineDispatcher limitedParallelism(int parallelism) {
    checkParallelism(parallelism);
    return limitIsolates(parallelism) ?? this;
  }

  /// Runs [block] on a worker isolate.
  ///
  /// Returns what [block] returns.
  @override
  Future<T> execute<T>(
    CoroutineContext context,
    FutureOr<T> Function(CoroutineScope it) block,
  ) => runOnIsolate(context, block);

  /// Names the dispatcher.
  @override
  String toString() {
    if (isolatesAvailable()) {
      return 'Dispatchers.isolate';
    }
    return 'Dispatchers.isolate(event loop)';
  }
}
