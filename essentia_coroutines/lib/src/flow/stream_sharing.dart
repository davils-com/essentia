/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';
import 'dart:math';

import 'package:essentia_coroutines/src/coroutine/coroutine_scope_builders.dart';
import 'package:essentia_coroutines/src/coroutine/coroutine_start.dart';
import 'package:essentia_coroutines/src/deferred/completable_deferred.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/flow/mutable_shared_flow.dart';
import 'package:essentia_coroutines/src/flow/mutable_state_flow.dart';
import 'package:essentia_coroutines/src/flow/shared_flow.dart';
import 'package:essentia_coroutines/src/flow/sharing_command.dart';
import 'package:essentia_coroutines/src/flow/sharing_started.dart';
import 'package:essentia_coroutines/src/flow/state_flow.dart';
import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/job/job_operations.dart';
import 'package:essentia_coroutines/src/scope/coroutine_scope.dart';
import 'package:essentia_coroutines/src/stream/stream_collection.dart';

/// The buffer a shared flow gets beyond its replay, Kotlin's
/// `Channel.CHANNEL_DEFAULT_CAPACITY`.
const _defaultCapacity = 64;

/// Kotlin's sharing `Flow` operators for streams, which turn a cold stream
/// into a hot flow.
///
/// A sharing coroutine is started in the given scope; it listens to this
/// stream when the `SharingStarted` strategy says so and emits what it gets
/// into the shared flow. Cancelling the scope stops the sharing, and an
/// error of this stream fails the sharing coroutine, and with it the scope
/// unless that is a supervisor.
///
/// A strategy that stops and starts again listens to this stream again, so
/// it has to be a stream that can be listened to more than once: a
/// broadcast stream, `Stream.multi`, a shared flow, or a stream made by a
/// function each time. A single subscription stream that already had its
/// listener throws a [StateError] on the second listen, which fails the
/// sharing coroutine; it never fails silently.
extension StreamSharing<T> on Stream<T> {
  /// Shares this stream with every listener of the returned flow, Kotlin's
  /// `shareIn`.
  ///
  /// The flow replays the last [replay] values to a new listener and
  /// buffers up to 64 values in all, so a listener that lags behind slows
  /// the sharing coroutine down only after that.
  ///
  /// ```dart
  /// final SharedFlow<Quote> quotes = quoteUpdates().shareIn(
  ///   scope,
  ///   SharingStarted.whileSubscribed(stopTimeout: 5.seconds),
  ///   replay: 1,
  /// );
  /// ```
  ///
  /// Returns the read-only shared flow.
  ///
  /// Throws an [ArgumentError] if [replay] is negative.
  SharedFlow<T> shareIn(
    CoroutineScope scope,
    SharingStarted started, {
    int replay = 0,
  }) {
    final shared = MutableSharedFlow<T>(
      replay: replay,
      extraBufferCapacity: max(replay, _defaultCapacity) - replay,
    );
    _launchSharing(scope, started, shared, shared.resetReplayCache);
    return shared.asSharedFlow();
  }

  /// Shares the latest value of this stream as a state flow starting with
  /// [initialValue], Kotlin's `stateIn`.
  ///
  /// When the strategy resets, the state goes back to [initialValue].
  ///
  /// ```dart
  /// final StateFlow<int> count = counts.stateIn(
  ///   scope,
  ///   SharingStarted.eagerly,
  ///   0,
  /// );
  /// ```
  ///
  /// Returns the read-only state flow.
  StateFlow<T> stateIn(
    CoroutineScope scope,
    SharingStarted started,
    T initialValue,
  ) {
    final state = MutableStateFlow<T>(initialValue);
    _launchSharing(scope, started, state, () => state.value = initialValue);
    return state.asStateFlow();
  }

  /// Shares the latest value of this stream as a state flow once it
  /// emitted its first value, Kotlin's suspending `stateIn(scope)`.
  ///
  /// The sharing starts at once and never stops; the state flow keeps the
  /// last value after this stream ended.
  ///
  /// Returns a future that completes with the read-only state flow once
  /// this stream emitted.
  ///
  /// Throws a [StateError] if this stream ends without a value, the error
  /// of this stream if it fails before, and a [CancellationException] if
  /// the waiting job is cancelled.
  Future<StateFlow<T>> awaitStateIn(CoroutineScope scope) {
    final result = CompletableDeferred<StateFlow<T>>();
    scope.launch((it) async {
      MutableStateFlow<T>? state;
      try {
        await collect((value) {
          final current = state;
          if (current != null) {
            current.value = value;
            return;
          }
          final created = MutableStateFlow<T>(value);
          state = created;
          result.complete(created.asStateFlow());
        });
      } on Object catch (error, stackTrace) {
        result.completeExceptionally(error, stackTrace);
        rethrow;
      }
      if (state == null) {
        result.completeExceptionally(StateError('Stream is empty'));
      }
    });
    return result;
  }

  /// Launches the coroutine that listens to this stream as [started] says
  /// and emits into [shared], calling [reset] on
  /// [SharingCommand.stopAndResetReplayCache], Kotlin's `launchSharing`.
  ///
  /// Returns the job of the sharing coroutine.
  Job _launchSharing(
    CoroutineScope scope,
    SharingStarted started,
    MutableSharedFlow<T> shared,
    void Function() reset,
  ) {
    final bool eager = identical(started, SharingStarted.eagerly);
    return scope.launch(
      start: eager ? CoroutineStart.defaultStart : CoroutineStart.undispatched,
      (it) async {
        if (eager) {
          await collect(shared.emit);
          return;
        }
        if (identical(started, SharingStarted.lazily)) {
          await shared.subscriptionCount.firstWhere((count) => count > 0);
          await collect(shared.emit);
          return;
        }
        Job? collecting;
        await started.command(shared.subscriptionCount).distinct().collect((
          command,
        ) async {
          final previous = collecting;
          collecting = null;
          await previous?.cancelAndJoin();
          switch (command) {
            case SharingCommand.start:
              collecting = it.launch(
                start: CoroutineStart.undispatched,
                (_) => collect(shared.emit),
              );
            case SharingCommand.stop:
              return;
            case SharingCommand.stopAndResetReplayCache:
              reset();
          }
        });
      },
    );
  }
}
