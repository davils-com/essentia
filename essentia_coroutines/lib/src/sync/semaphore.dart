/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';
import 'dart:collection';

import 'package:essentia_coroutines/src/continuation/cancellable_continuation.dart';
import 'package:essentia_coroutines/src/continuation/suspension.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/scheduler/scheduled_task.dart';
import 'package:essentia_coroutines/src/scheduler/scheduler.dart';

/// A counting semaphore, Kotlin's `kotlinx.coroutines.sync.Semaphore`.
///
/// It hands out up to [permits] permits at once. An acquirer that finds
/// none free waits, oldest first. A fair semaphore hands a permit given
/// back straight to the oldest waiter, so a newcomer never overtakes one;
/// an unfair one leaves it free until the woken waiter resumes, and a
/// newcomer arriving in between takes it.
///
/// The number of permits can change while they are held: [resize] to fewer
/// than are held takes nothing away, and new acquirers wait until enough
/// were given back.
///
/// Waiting is cancellable like Kotlin's: an acquirer whose job is
/// cancelled stops waiting with the job's [CancellationException] and never
/// holds a permit.
///
/// ```dart
/// final downloads = Semaphore(4);
/// Future<Bytes> download(Uri uri) =>
///     downloads.withPermit(() => client.get(uri));
/// ```
final class Semaphore {
  /// Creates a semaphore handing out up to [permits] permits, of which
  /// [acquiredPermits] are taken from the start, serving waiters strictly
  /// oldest first when [fair].
  ///
  /// A semaphore of zero permits admits nobody until it is [resize]d,
  /// which suits a limit read from a configuration.
  ///
  /// Throws a [RangeError] if [permits] is negative, or if
  /// [acquiredPermits] lies outside zero to [permits].
  Semaphore(int permits, {int acquiredPermits = 0, this.fair = true})
    : _limit = permits,
      _held = acquiredPermits {
    if (permits < 0) {
      throw RangeError.range(permits, 0, null, 'permits');
    }
    if (acquiredPermits < 0 || acquiredPermits > permits) {
      throw RangeError.range(acquiredPermits, 0, permits, 'acquiredPermits');
    }
  }

  /// Whether a newcomer queues behind every waiter.
  ///
  /// Changing it applies to the acquirers that ask from now on.
  bool fair;

  /// How many permits may be held at once.
  int _limit;

  /// How many permits are held, which may exceed [_limit] after [resize].
  int _held;

  /// The acquirers waiting for a permit, oldest first, with the deadline of
  /// a bounded wait.
  final _waiting =
      Queue<
        ({CancellableContinuation<bool> continuation, ScheduledTask? deadline})
      >();

  /// Whether an unfair hand over is scheduled.
  var _handOverScheduled = false;

  /// How many permits the semaphore hands out at once.
  int get permits => _limit;

  /// How many permits are free right now, never below zero.
  int get availablePermits => _held >= _limit ? 0 : _limit - _held;

  /// How many acquirers wait for a permit.
  int get waitingCount => _waiting.length;

  /// Takes a free permit without waiting.
  ///
  /// A fair semaphore refuses while anybody waits.
  ///
  /// Returns `true` when a permit was taken, `false` when none was free.
  bool tryAcquire() {
    if (fair && _waiting.isNotEmpty) {
      return false;
    }
    if (_held >= _limit) {
      return false;
    }
    _held++;
    return true;
  }

  /// Takes a permit, waiting for one if none is free, Kotlin's
  /// `acquire()`.
  ///
  /// Returns a future that completes once the permit is taken.
  ///
  /// Throws a [CancellationException] if the current job is cancelled
  /// before a permit is handed over.
  Future<void> acquire() => _acquire(null, Scheduler.system).then(_ignore);

  /// Takes a permit, waiting at most [timeout] for one.
  ///
  /// A zero or negative [timeout] does not wait at all. The wait is measured
  /// on [scheduler], the one of the current context unless given. A waiter
  /// that gives up leaves the queue.
  ///
  /// Returns `true` when a permit was taken in time, `false` otherwise.
  ///
  /// Throws a [CancellationException] if the current job is cancelled
  /// before a permit is handed over.
  Future<bool> tryAcquireWithin(Duration timeout, {Scheduler? scheduler}) =>
      _acquire(timeout, scheduler ?? Scheduler.current);

  /// Gives a permit back, handing it on to the oldest waiter if the number
  /// of permits allows, Kotlin's `release()`.
  ///
  /// Throws a [StateError] if more permits are given back than were taken.
  void release() {
    if (_held <= 0) {
      throw StateError('Released more permits than were acquired');
    }
    _held--;
    _dispatch();
  }

  /// Changes the number of permits to [permits], handing new ones to the
  /// waiters.
  ///
  /// Fewer permits take nothing away from the holders; they give them back
  /// as they finish.
  ///
  /// Throws a [RangeError] if [permits] is negative.
  void resize(int permits) {
    if (permits < 0) {
      throw RangeError.range(permits, 0, null, 'permits');
    }
    _limit = permits;
    _dispatch();
  }

  /// Runs [action] while holding a permit, waiting for one if none is free,
  /// Kotlin's `withPermit`.
  ///
  /// The permit is given back once [action] completes, whether it succeeds
  /// or fails.
  ///
  /// Returns what [action] returns.
  ///
  /// Throws what [action] throws, and a [CancellationException] if the
  /// current job is cancelled before a permit is handed over.
  Future<R> withPermit<R>(FutureOr<R> Function() action) async {
    await acquire();
    try {
      return await action();
    } finally {
      release();
    }
  }

  /// Renders the permits that are free and the waiters.
  @override
  String toString() =>
      'Semaphore($availablePermits of $_limit free, '
      '${_waiting.length} waiting)';

  /// Takes a permit, waiting for one up to [timeout] on [scheduler], or for
  /// as long as it takes when [timeout] is `null`.
  ///
  /// Returns whether a permit was taken.
  Future<bool> _acquire(Duration? timeout, Scheduler scheduler) {
    try {
      ensureActive();
    } on CancellationException catch (cause, stackTrace) {
      return Future<bool>.error(cause, stackTrace);
    }
    if (tryAcquire()) {
      return Future<bool>.value(true);
    }
    if (timeout != null && timeout <= Duration.zero) {
      return Future<bool>.value(false);
    }
    return suspendCancellableCoroutine<bool>((it) {
      final ScheduledTask? deadline = timeout == null
          ? null
          : scheduler.schedule(timeout, () {
              if (_remove(it)) {
                it.resume(false);
              }
            });
      _waiting.add((continuation: it, deadline: deadline));
      it.invokeOnCancellation((cause) {
        deadline?.cancel();
        _remove(it);
      });
    });
  }

  /// Takes the waiter of [continuation] out of the queue.
  ///
  /// Returns whether it was still waiting.
  bool _remove(CancellableContinuation<bool> continuation) {
    final int before = _waiting.length;
    _waiting.removeWhere(
      (waiter) => identical(waiter.continuation, continuation),
    );
    return _waiting.length < before;
  }

  /// Hands free permits to the waiters: at once when fair, once the woken
  /// waiters resume when not.
  void _dispatch() {
    if (_waiting.isEmpty || _held >= _limit) {
      return;
    }
    if (fair) {
      _handOver();
      return;
    }
    if (_handOverScheduled) {
      return;
    }
    _handOverScheduled = true;
    scheduleMicrotask(() {
      _handOverScheduled = false;
      _handOver();
    });
  }

  /// Hands one free permit after the other to the oldest waiter, as long
  /// as both remain. A permit handed to a waiter whose job was cancelled
  /// before it resumed is given back.
  void _handOver() {
    while (_waiting.isNotEmpty && _held < _limit) {
      _held++;
      final (
        :CancellableContinuation<bool> continuation,
        :ScheduledTask? deadline,
      ) = _waiting
          .removeFirst();
      deadline?.cancel();
      continuation.resume(true, onCancellation: (cause, value) => release());
    }
  }

  /// Drops the outcome of an unbounded wait.
  static void _ignore(bool acquired) {}
}
