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

import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/sync/semaphore.dart';

/// A lock that one piece of asynchronous work holds at a time.
///
/// Dart runs one isolate on one thread, but an asynchronous section that
/// awaits in the middle can still interleave with another one; a mutex keeps
/// such sections apart. Waiters are served oldest first, and waiting is
/// cancellable like a [Semaphore]'s. The lock is not reentrant: work that
/// holds it and asks for it again waits for itself forever.
///
/// ```dart
/// final writing = Mutex();
/// Future<void> save(Settings settings) =>
///     writing.withLock(() => store.write(settings));
/// ```
final class Mutex {
  /// Creates a mutex, already locked when [locked] is `true`.
  Mutex({bool locked = false})
    : _permit = Semaphore(1, acquiredPermits: locked ? 1 : 0);

  /// The single permit that is the lock.
  final Semaphore _permit;

  /// Whether somebody holds the lock.
  bool get isLocked => _permit.availablePermits == 0;

  /// Takes the lock without waiting.
  ///
  /// Returns `true` when the lock was taken, `false` when it is held.
  bool tryLock() => _permit.tryAcquire();

  /// Takes the lock, waiting until it is free.
  ///
  /// Returns a future that completes once the lock is held.
  ///
  /// Throws a [CancellationException] if the current job is cancelled
  /// before the lock is handed over.
  Future<void> lock() => _permit.acquire();

  /// Gives the lock back, handing it to the oldest waiter if there is one.
  ///
  /// Throws a [StateError] if the lock is not held.
  void unlock() {
    if (!isLocked) {
      throw StateError('Unlocked a mutex that is not locked');
    }
    _permit.release();
  }

  /// Runs [action] while holding the lock.
  ///
  /// The lock is given back once [action] completes, whether it succeeds or
  /// fails.
  ///
  /// Returns what [action] returns.
  ///
  /// Throws what [action] throws, and a [CancellationException] if the
  /// current job is cancelled before the lock is handed over.
  Future<R> withLock<R>(FutureOr<R> Function() action) =>
      _permit.withPermit(action);

  /// Renders whether the lock is held.
  @override
  String toString() => isLocked ? 'Mutex(locked)' : 'Mutex(unlocked)';
}
