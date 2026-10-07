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
import 'package:essentia/src/coroutines/coroutine_scope.dart';
import 'package:essentia/src/coroutines/isolate_platform_web.dart'
    if (dart.library.io) 'package:essentia/src/coroutines/isolate_platform_io.dart';
import 'package:essentia/src/coroutines/parallelism.dart';
import 'package:essentia/src/coroutines/remote_dispatcher.dart';
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
