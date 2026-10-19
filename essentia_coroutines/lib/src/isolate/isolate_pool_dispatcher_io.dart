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
import 'package:essentia_coroutines/src/dispatcher/remote_dispatcher.dart';
import 'package:essentia_coroutines/src/isolate/isolate_pool_io.dart';
import 'package:essentia_coroutines/src/scope/coroutine_scope.dart';
import 'package:essentia_coroutines/src/sync/semaphore.dart';
import 'package:meta/meta.dart';

/// A view of `Dispatchers.isolate` that runs at most [parallelism] bodies at
/// once on the shared pool.
@internal
final class IsolatePoolDispatcherIo extends CoroutineDispatcher
    implements RemoteDispatcher {
  /// Creates the view on [_pool], running at most [parallelism] bodies at
  /// once.
  IsolatePoolDispatcherIo(this._pool, this.parallelism)
    : _limit = Semaphore(parallelism);

  /// The pool of worker isolates.
  final IsolatePoolIo _pool;

  /// How many bodies of this view run at once.
  final int parallelism;

  /// The permits of the view.
  final Semaphore _limit;

  /// Bodies run on worker isolates.
  @override
  bool get remote => true;

  /// Runs [block] on the event loop; bodies of coroutines go through
  /// [execute] instead.
  @override
  void dispatch(CoroutineContext context, Zone zone, void Function() block) =>
      zone.scheduleMicrotask(block);

  /// A view on the same pool that runs at most [parallelism] bodies at
  /// once, independently of this one.
  ///
  /// Returns the view.
  ///
  /// Throws a [RangeError] if [parallelism] is smaller than one.
  @override
  CoroutineDispatcher limitedParallelism(int parallelism) {
    checkParallelism(parallelism);
    return IsolatePoolDispatcherIo(_pool, parallelism);
  }

  /// Runs [block] on a worker isolate once the view has a free permit.
  ///
  /// Returns what [block] returns.
  @override
  Future<T> execute<T>(
    CoroutineContext context,
    FutureOr<T> Function(CoroutineScope it) block,
  ) => _limit.withPermit(() => _pool.run(context, block));

  /// Names the view.
  @override
  String toString() => 'Dispatchers.isolate.limitedParallelism($parallelism)';
}
