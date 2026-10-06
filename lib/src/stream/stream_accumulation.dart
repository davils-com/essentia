/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/stream/emission.dart';
import 'package:essentia/src/stream/relay.dart';

/// Kotlin's accumulating `Flow` operators for streams.
extension StreamAccumulation<T> on Stream<T> {
  /// Emits the first element and then every element combined with the
  /// value emitted before it, the counterpart of Kotlin's `runningReduce`.
  ///
  /// `[1, 2, 3]` reduced by addition becomes `[1, 3, 6]`. An error thrown
  /// by [combine] becomes an error event and leaves the running value
  /// unchanged; errors of this stream are passed on unchanged.
  ///
  /// Every listener keeps its own running value, and pause, resume and
  /// cancel reach this stream.
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  Stream<T> runningReduce(T Function(T accumulator, T element) combine) =>
      relay<T, T>(this, (sink) {
        ({T value})? accumulated;
        return (
          onData: (element) {
            final previous = accumulated;
            emitCatching(sink, () {
              final T value = previous == null
                  ? element
                  : combine(previous.value, element);
              accumulated = (value: value);
              return value;
            });
          },
          onDone: closing(sink),
          onCancel: ignoringCancel,
        );
      });
}
