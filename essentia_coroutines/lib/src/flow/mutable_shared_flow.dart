/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/channels/buffer_overflow.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/flow/flow_collector.dart';
import 'package:essentia_coroutines/src/flow/shared_flow.dart';
import 'package:essentia_coroutines/src/flow/shared_flow_impl.dart';
import 'package:essentia_coroutines/src/flow/state_flow.dart';

/// A shared flow that values are emitted into, Kotlin's
/// `MutableSharedFlow`.
///
/// Values go into one buffer shared by every listener: the last `replay`
/// values are kept for new listeners, and `extraBufferCapacity` more make
/// room for listeners that lag behind. Once the buffer is full because a
/// listener still has to take its oldest value, the `onBufferOverflow`
/// policy decides: [BufferOverflow.suspend] makes [emit] wait for that
/// listener, [BufferOverflow.dropOldest] drops the oldest value and
/// [BufferOverflow.dropLatest] the new one. Without listeners [emit] never
/// waits, and only the replay values are kept.
///
/// ```dart
/// final class EventBus {
///   final _events = MutableSharedFlow<Event>();
///
///   SharedFlow<Event> get events => _events.asSharedFlow();
///
///   Future<void> produceEvent(Event event) => _events.emit(event);
/// }
/// ```
abstract interface class MutableSharedFlow<T>
    implements SharedFlow<T>, FlowCollector<T> {
  /// Creates a shared flow keeping [replay] values for new listeners and
  /// buffering [extraBufferCapacity] more, with [onBufferOverflow] deciding
  /// what happens when the buffer is full, Kotlin's `MutableSharedFlow()`.
  ///
  /// Throws an [ArgumentError] if [replay] or [extraBufferCapacity] is
  /// negative, or if [onBufferOverflow] is not [BufferOverflow.suspend]
  /// while both are zero.
  factory MutableSharedFlow({
    int replay = 0,
    int extraBufferCapacity = 0,
    BufferOverflow onBufferOverflow = BufferOverflow.suspend,
  }) {
    if (replay < 0) {
      throw ArgumentError(
        'replay cannot be negative, but was $replay',
        'replay',
      );
    }
    if (extraBufferCapacity < 0) {
      throw ArgumentError(
        'extraBufferCapacity cannot be negative, but was '
            '$extraBufferCapacity',
        'extraBufferCapacity',
      );
    }
    if (replay == 0 &&
        extraBufferCapacity == 0 &&
        onBufferOverflow != BufferOverflow.suspend) {
      throw ArgumentError(
        'replay or extraBufferCapacity must be positive with non-default '
            'onBufferOverflow strategy $onBufferOverflow',
        'onBufferOverflow',
      );
    }
    return SharedFlowImpl<T>(
      replay,
      replay + extraBufferCapacity,
      onBufferOverflow,
    );
  }

  /// How many listeners the flow has, Kotlin's `subscriptionCount`.
  ///
  /// It changes as soon as a listener subscribes or cancels.
  StateFlow<int> get subscriptionCount;

  /// Emits [value] to every listener, Kotlin's `emit`.
  ///
  /// It does not look at the job of the emitting code unless it has to
  /// wait.
  ///
  /// Returns a future that completes once the value is in the buffer; with
  /// [BufferOverflow.suspend] it waits while the buffer is full.
  ///
  /// Throws a [CancellationException] if the emitting job is cancelled
  /// while it waits.
  @override
  Future<void> emit(T value);

  /// Emits [value] without waiting, Kotlin's `tryEmit`.
  ///
  /// Returns `true` when the value was emitted or dropped by the overflow
  /// policy, `false` when the buffer is full and the policy is
  /// [BufferOverflow.suspend].
  bool tryEmit(T value);

  /// Forgets the replay values, Kotlin's `resetReplayCache`; new listeners
  /// start with the next emitted value.
  ///
  /// Values a current listener has not taken yet are still delivered to it.
  void resetReplayCache();

  /// A read-only view of this flow, Kotlin's `asSharedFlow`.
  ///
  /// Returns the view, which cannot be cast back to emit.
  SharedFlow<T> asSharedFlow();
}
