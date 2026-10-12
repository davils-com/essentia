/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';

/// Where the values of a stream are emitted to, Kotlin's `FlowCollector`.
///
/// A [FlowCollector] is handed to the blocks of `transformLatest` and
/// `catchError`, and a `MutableSharedFlow` is one, so a stream can be
/// collected into a shared flow with `stream.collect(flow.emit)`.
abstract interface class FlowCollector<T> {
  /// Emits [value], Kotlin's `emit`.
  ///
  /// Returns a future that completes once the value is taken; it waits
  /// while the receiving side is paused or its buffer is full.
  ///
  /// Throws a [CancellationException] if the emitting code is cancelled or
  /// nobody listens any more.
  Future<void> emit(T value);
}
