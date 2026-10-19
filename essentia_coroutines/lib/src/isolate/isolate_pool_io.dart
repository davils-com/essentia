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
