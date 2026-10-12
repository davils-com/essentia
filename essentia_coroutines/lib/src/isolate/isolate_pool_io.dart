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
import 'package:essentia_coroutines/src/isolate/isolate_worker_io.dart';
import 'package:essentia_coroutines/src/scope/coroutine_scope.dart';
import 'package:essentia_coroutines/src/sync/semaphore.dart';
import 'package:meta/meta.dart';

/// A pool of worker isolates, each running one body at a time.
///
/// Workers are spawned on demand up to the size of the pool and kept once
/// idle; an idle worker does not keep the program alive.
@internal
final class IsolatePoolIo {
  /// Creates a pool of at most [size] workers.
  IsolatePoolIo(int size) : _slots = Semaphore(size);

  /// The workers that may run at once.
  final Semaphore _slots;

  /// The workers that wait for a body.
  final _idle = <IsolateWorkerIo>[];

  /// Runs [block] with the sendable elements of [context] on a worker,
  /// waiting for one to be free.
  ///
  /// Returns what [block] returns.
  Future<T> run<T>(
    CoroutineContext context,
    FutureOr<T> Function(CoroutineScope it) block,
  ) async {
    await _slots.acquire();
    final IsolateWorkerIo worker = _idle.isEmpty
        ? IsolateWorkerIo()
        : _idle.removeLast();
    try {
      return await worker.run(context, block);
    } finally {
      _slots.release();
      if (worker.isAlive) {
        _idle.add(worker);
      }
    }
  }
}
