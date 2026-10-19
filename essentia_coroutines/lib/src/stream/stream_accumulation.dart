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

import 'package:essentia_coroutines/src/stream/emission.dart';
import 'package:essentia_coroutines/src/stream/relay.dart';

/// The accumulating operators for streams.
extension StreamAccumulation<T> on Stream<T> {
  /// Emits the first element and then every element combined with the
  /// value emitted before it.
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

  /// Emits [initial] and then every element folded into the value emitted
  /// before it with [operation].
  ///
  /// `[1, 2, 3]` folded from `0` by addition becomes `[0, 1, 3, 6]`.
  /// [initial] is emitted as soon as a listener subscribes. An error thrown
  /// by [operation] becomes an error event and leaves the running value
  /// unchanged; errors of this stream are passed on unchanged.
  ///
  /// Every listener keeps its own running value, and pause, resume and
  /// cancel reach this stream.
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  Stream<R> runningFold<R>(
    R initial,
    R Function(R accumulator, T element) operation,
  ) => relay<T, R>(this, (sink) {
    var accumulator = initial;
    sink.add(initial);
    return (
      onData: (element) {
        final previous = accumulator;
        emitCatching(sink, () => accumulator = operation(previous, element));
      },
      onDone: closing(sink),
      onCancel: ignoringCancel,
    );
  });

  /// Emits [initial] and then every element folded into the value emitted
  /// before it with [operation], the same as [runningFold].
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  Stream<R> scan<R>(
    R initial,
    R Function(R accumulator, T element) operation,
  ) => runningFold(initial, operation);
}
