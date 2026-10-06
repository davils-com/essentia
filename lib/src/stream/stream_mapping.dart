/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/stream/concurrent_async_expand.dart';
import 'package:essentia/src/stream/relay.dart';
import 'package:essentia/src/stream/stream_semaphore.dart';
import 'package:essentia/src/stream/switch_map.dart';

/// How many inner streams `flatMapMerge` runs at once unless told
/// otherwise, the default of Kotlin's `DEFAULT_CONCURRENCY`.
const _defaultConcurrency = 16;

/// Kotlin's mapping `Flow` operators for streams.
extension StreamMapping<T> on Stream<T> {
  /// Maps every element with [transform] and drops the `null` results, the
  /// counterpart of Kotlin's `mapNotNull`.
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  Stream<R> mapNotNull<R extends Object>(R? Function(T element) transform) =>
      expand((element) => <R>[?transform(element)]);

  /// Pairs every element with its position, starting at zero, the
  /// counterpart of Kotlin's `withIndex`.
  ///
  /// Every listener counts from zero, and pause, resume and cancel reach
  /// this stream.
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  Stream<(int, T)> get indexed => relay<T, (int, T)>(this, (sink) {
    var index = 0;
    return (
      onData: (element) => sink.add((index++, element)),
      onDone: closing(sink),
      onCancel: ignoringCancel,
    );
  });

  /// Maps every element with [transform] and emits only the result for the
  /// latest element, the counterpart of Kotlin's `mapLatest`.
  ///
  /// When an element arrives while the result of the previous one is still
  /// pending, that result is dropped. Dart cannot cancel a running future,
  /// so the dropped computation keeps running; only its result is ignored.
  /// The result ends once this stream ended and the latest result arrived.
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  Stream<R> mapLatest<R>(Future<R> Function(T element) transform) =>
      switchMap<T, R>(
        this,
        (element) => Stream<R>.fromFuture(transform(element)),
      );

  /// Maps every element to an inner stream with [transform] and merges the
  /// inner streams, running up to [concurrency] of them at once, the
  /// counterpart of Kotlin's `flatMapMerge`.
  ///
  /// An inner stream beyond [concurrency] is opened only once a running
  /// one ended. The limit is shared by every listener of the result.
  /// Events are emitted in the order the inner streams emit them, and an
  /// error thrown by [transform] or emitted by an inner stream is passed on
  /// without ending the result.
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  ///
  /// Throws a [RangeError] if [concurrency] is smaller than one.
  Stream<R> flatMapMerge<R>(
    Stream<R> Function(T element) transform, {
    int concurrency = _defaultConcurrency,
  }) {
    final semaphore = StreamSemaphore(concurrency);
    return concurrentAsyncExpand<T, R>(
      this,
      (element) => _whilePermitted(semaphore, () => transform(element)),
    );
  }
}

/// Defers [open] until [semaphore] grants a permit and holds that permit
/// until the opened stream ends or its listener cancels.
///
/// A listener that cancels before the permit is granted never opens the
/// stream, and an error thrown by [open] becomes an error event.
///
/// Returns a single subscription stream of the events of the opened stream.
Stream<R> _whilePermitted<R>(
  StreamSemaphore semaphore,
  Stream<R> Function() open,
) {
  final controller = StreamController<R>();
  Future<void> forward() async {
    if (!controller.hasListener) {
      return;
    }
    try {
      await controller.addStream(open());
    } on Object catch (error, stackTrace) {
      controller.addError(error, stackTrace);
    }
  }

  controller.onListen = () =>
      unawaited(semaphore.withPermit(forward).whenComplete(controller.close));
  return controller.stream;
}
