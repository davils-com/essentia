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

import 'package:meta/meta.dart';

/// A counting semaphore that bounds how many inner streams of
/// `flatMapMerge` run at the same time.
///
/// Only what the stream operators need: an action runs once a permit is
/// free, and waiting actions are admitted oldest first.
@internal
final class StreamSemaphore {
  /// Creates a semaphore handing out up to [permits] permits at once.
  ///
  /// Throws a [RangeError] if [permits] is smaller than one.
  StreamSemaphore(this.permits) : _available = permits {
    if (permits < 1) {
      throw RangeError.range(permits, 1, null, 'permits');
    }
  }

  /// How many permits the semaphore hands out at once.
  final int permits;

  /// How many permits are free right now.
  int _available;

  /// The acquirers waiting for a permit, oldest first.
  final _waiting = Queue<Completer<void>>();

  /// How many permits are free right now.
  int get availablePermits => _available;

  /// How many acquirers wait for a permit.
  int get waitingCount => _waiting.length;

  /// Runs [action] while holding a permit, waiting for one if none is free.
  ///
  /// The permit is given back once [action] completes, whether it succeeds
  /// or fails.
  ///
  /// Returns what [action] returns.
  Future<R> withPermit<R>(Future<R> Function() action) async {
    await _acquire();
    try {
      return await action();
    } finally {
      _release();
    }
  }

  /// Takes a free permit, or waits for one to be handed over.
  Future<void> _acquire() {
    if (_available > 0) {
      _available--;
      return Future<void>.value();
    }
    final waiter = Completer<void>();
    _waiting.add(waiter);
    return waiter.future;
  }

  /// Hands the permit to the oldest waiter, or makes it free again.
  void _release() {
    if (_waiting.isNotEmpty) {
      _waiting.removeFirst().complete();
      return;
    }
    _available++;
  }
}
