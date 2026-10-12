/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/continuation/suspension.dart';
import 'package:essentia_coroutines/src/coroutine/coroutine_scope_builders.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/scope/coroutine_scope.dart';
import 'package:essentia_coroutines/src/stream/stream_cancellation.dart';
import 'package:essentia_coroutines/src/stream/subscription_cancel.dart';
import 'package:essentia_coroutines/src/stream/switch_map.dart';

/// Kotlin's terminal `Flow` operators for streams.
extension StreamCollection<T> on Stream<T> {
  /// Runs [action] for every element and abandons the action of an element
  /// as soon as the next one arrives, the counterpart of Kotlin's
  /// `collectLatest`.
  ///
  /// Every action runs in a job of its own, which is cancelled when the
  /// next element arrives, so its cancellable waits such as `delay` end
  /// with a `CancellationException`. A plain future it awaits cannot be
  /// interrupted; such an action keeps running, and only its completion is
  /// no longer waited for.
  ///
  /// Returns a future that completes once this stream ended and the action
  /// of its last element completed, or with the first error of this stream
  /// or of an action that was still awaited.
  Future<void> collectLatest(Future<void> Function(T element) action) =>
      switchMap<T, void>(
        this,
        (element) => Stream<void>.fromFuture(action(element)),
      ).drain<void>();

  /// Runs [action] for every element, waiting for each to complete before
  /// taking the next, Kotlin's `collect`.
  ///
  /// The stream is paused while [action] runs, so a slow action slows a
  /// [Stream] made with `async*` or a shared flow down instead of letting
  /// values pile up. Without [action] the elements are taken and dropped,
  /// Kotlin's `collect()`. Collecting is cancellable: once the job of the
  /// collecting code is cancelled, the subscription is cancelled and no
  /// further element is handed to [action].
  ///
  /// ```dart
  /// scope.launch((it) => counter.collect((value) => print(value)));
  /// ```
  ///
  /// Returns a future that completes once the stream ended.
  ///
  /// Throws the first error of the stream or of [action], ending the
  /// collection, and a [CancellationException] if the collecting job is
  /// cancelled.
  Future<void> collect([FutureOr<void> Function(T value)? action]) {
    final done = Completer<void>();
    final StreamSubscription<T> subscription = cancellable().listen(null);

    void fail(Object error, StackTrace stackTrace) {
      if (done.isCompleted) {
        return;
      }
      afterCancel(
        subscription.cancel(),
        () => done.completeError(error, stackTrace),
      );
    }

    subscription
      ..onData((value) {
        final Object? pending;
        try {
          ensureActive();
          pending = action?.call(value);
        } on Object catch (error, stackTrace) {
          fail(error, stackTrace);
          return;
        }
        if (pending is Future<void>) {
          subscription.pause();
          pending.then((_) => subscription.resume(), onError: fail).ignore();
        }
      })
      ..onError(fail)
      ..onDone(done.complete);
    return done.future;
  }

  /// Collects the stream in a coroutine started in [scope], Kotlin's
  /// `launchIn`.
  ///
  /// Elements are dropped, so the stream is used for what it does on the
  /// way, typically with `onEach`:
  ///
  /// ```dart
  /// events.onEach(handle).launchIn(scope);
  /// ```
  ///
  /// Returns the job of the collecting coroutine; cancelling it cancels the
  /// subscription. An error of the stream fails the job.
  Job launchIn(CoroutineScope scope) => scope.launch((it) => collect());

  /// The first element, or `null` when the stream ends without one,
  /// Kotlin's `firstOrNull`.
  ///
  /// Stops listening to the stream once the first element arrived.
  ///
  /// Returns the element or `null`; the future fails with the first error
  /// of the stream.
  Future<T?> get firstOrNull {
    final found = Completer<T?>();
    final StreamSubscription<T> subscription = listen(
      null,
      onError: found.completeError,
      onDone: () => found.complete(null),
      cancelOnError: true,
    );
    subscription.onData((value) {
      afterCancel(subscription.cancel(), () => found.complete(value));
    });
    return found.future;
  }

  /// The only element, or `null` when the stream ends without one or emits
  /// more than one, Kotlin's `singleOrNull`.
  ///
  /// Stops listening to the stream once a second element arrived.
  ///
  /// Returns the element or `null`; the future fails with the first error
  /// of the stream.
  Future<T?> get singleOrNull {
    final single = Completer<T?>();
    ({T value})? found;
    final StreamSubscription<T> subscription = listen(
      null,
      onError: single.completeError,
      onDone: () => single.complete(found?.value),
      cancelOnError: true,
    );
    subscription.onData((value) {
      if (found == null) {
        found = (value: value);
        return;
      }
      afterCancel(subscription.cancel(), () => single.complete(null));
    });
    return single.future;
  }

  /// Finds the first element that satisfies [test], the counterpart of
  /// Kotlin's `firstOrNull` with a predicate.
  ///
  /// Stops listening to this stream as soon as an element matches.
  ///
  /// Returns the element, or `null` when this stream ends without one; the
  /// future fails with the first error of this stream or of [test].
  Future<T?> firstWhereOrNull(bool Function(T element) test) async {
    await for (final T element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }

  /// Counts the elements that satisfy [test], the counterpart of Kotlin's
  /// `count` with a predicate.
  ///
  /// Returns the count once this stream ended; the future fails with the
  /// first error of this stream or of [test].
  Future<int> countWhere(bool Function(T element) test) => where(test).length;
}
