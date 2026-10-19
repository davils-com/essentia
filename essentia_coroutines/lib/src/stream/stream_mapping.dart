/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/context/coroutine_context_access.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_zone.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/flow/flow_collector.dart';
import 'package:essentia_coroutines/src/stream/concurrent_async_expand.dart';
import 'package:essentia_coroutines/src/stream/controller_collector.dart';
import 'package:essentia_coroutines/src/stream/relay.dart';
import 'package:essentia_coroutines/src/stream/switch_map.dart';
import 'package:essentia_coroutines/src/sync/semaphore.dart';

/// How many inner streams `flatMapMerge` runs at once unless told
/// otherwise.
const _defaultConcurrency = 16;

/// The mapping operators for streams.
extension StreamMapping<T> on Stream<T> {
  /// Maps every element with [transform] and drops the `null` results.
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  Stream<R> mapNotNull<R extends Object>(R? Function(T element) transform) =>
      expand((element) => <R>[?transform(element)]);

  /// Pairs every element with its position, starting at zero.
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
  /// latest element.
  ///
  /// When an element arrives while the result of the previous one is still
  /// pending, that result is dropped. [transform] runs in a job of its own,
  /// which is cancelled then, so its cancellable waits such as `delay` end
  /// with a `CancellationException`; a plain future it awaits cannot be
  /// interrupted, and only its result is ignored. The result ends once this
  /// stream ended and the latest result arrived.
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  Stream<R> mapLatest<R>(Future<R> Function(T element) transform) =>
      switchMap<T, R>(
        this,
        (element) => Stream<R>.fromFuture(transform(element)),
      );

  /// Maps every element to an inner stream with [transform] and emits the
  /// events of the latest inner stream only.
  ///
  /// When an element arrives, the inner stream of the previous one is
  /// cancelled, and the new one is listened to once that cancel completed;
  /// this stream is paused meanwhile. Every inner stream is created and
  /// listened to in a job of its own, which is cancelled before its
  /// subscription is, so a `delay` in an `async*` generator ends at once
  /// instead of holding the switch up. Errors of this stream, of
  /// [transform] and of the inner streams are passed on without ending the
  /// result, which ends once this stream and the latest inner stream ended.
  ///
  /// ```dart
  /// Stream<String> requests(int i) async* {
  ///   yield '$i: First';
  ///   await delay(500.milliseconds);
  ///   yield '$i: Second';
  /// }
  ///
  /// numbers.flatMapLatest(requests); // 1: First, 2: First, 3: First, ...
  /// ```
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  Stream<R> flatMapLatest<R>(Stream<R> Function(T value) transform) =>
      switchMap<T, R>(this, transform);

  /// Maps every element to an inner stream with [transform] and emits the
  /// inner streams one after the other.
  ///
  /// This stream is paused while an inner stream runs. It is Dart's
  /// `asyncExpand` under another name.
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  Stream<R> flatMapConcat<R>(Stream<R> Function(T value) transform) =>
      asyncExpand(transform);

  /// Runs [transform] for every element, which emits through the collector
  /// `it` it is handed, and cancels the run of the previous element when a
  /// new one arrives.
  ///
  /// Every run happens in a job of its own: when the next element arrives,
  /// that job is cancelled, so `delay` and other cancellable waits of the
  /// superseded run end with a `CancellationException`, and its `emit`
  /// throws one. The next run starts once the cancelled one let go. A run
  /// waits in `emit` while the listener is paused. An error a run throws is
  /// passed on without ending the result; its own cancellation is not an
  /// error. The result ends once this stream ended and the latest run
  /// completed.
  ///
  /// ```dart
  /// counts.transformLatest<String>((it, count) async {
  ///   await delay(1.seconds);
  ///   await it.emit('settled at $count');
  /// });
  /// ```
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  Stream<R> transformLatest<R>(
    FutureOr<void> Function(FlowCollector<R> it, T value) transform,
  ) => switchMap<T, R>(this, (value) => _run(transform, value));

  /// Runs [action] for every element before it is emitted.
  ///
  /// When [action] returns a future, this stream is paused until it
  /// completes, and the element is emitted afterwards. An error of
  /// [action] becomes an error event in place of the element.
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  Stream<T> onEach(FutureOr<void> Function(T value) action) =>
      asyncMap((value) {
        final Object? pending = action(value);
        if (pending is Future<void>) {
          return pending.then((_) => value);
        }
        return value;
      });

  /// Maps every element to an inner stream with [transform] and merges the
  /// inner streams, running up to [concurrency] of them at once.
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
    if (concurrency < 1) {
      throw RangeError.range(concurrency, 1, null, 'concurrency');
    }
    final semaphore = Semaphore(concurrency);
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
Stream<R> _whilePermitted<R>(Semaphore semaphore, Stream<R> Function() open) {
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

/// The run of [transform] for [value] as a stream of what it emits.
///
/// The run starts when the stream is listened to, in the zone of the
/// listener, which carries the job of the run. It ends the stream once it
/// completes, and an error it throws becomes an error event, unless it is
/// the cancellation of that job.
///
/// Returns the single subscription stream of the run.
Stream<R> _run<T, R>(
  FutureOr<void> Function(FlowCollector<R> it, T value) transform,
  T value,
) => Stream<R>.multi((controller) {
  final collector = ControllerCollector<R>(controller);
  controller
    ..onResume = collector.release
    ..onCancel = collector.release;
  unawaited(
    Future<void>.sync(() => transform(collector, value)).then(
      (_) => controller.close(),
      onError: (Object error, StackTrace stackTrace) {
        if (error is! CancellationException ||
            currentCoroutineContext().isActive) {
          controller.addError(error, stackTrace);
        }
        return controller.close();
      },
    ),
  );
});
