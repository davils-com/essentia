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

import 'package:meta/meta.dart';

/// Running folds and reductions, and the reductions that tolerate a source
/// without elements.
extension IterableAccumulation<T> on Iterable<T> {
  /// Folds the elements step by step, starting with [initial].
  ///
  /// Returns [initial] followed by every intermediate value, lazily.
  @useResult
  Iterable<R> runningFold<R>(
    R initial,
    R Function(R accumulator, T element) combine,
  ) => runningFoldIndexed(
    initial,
    (_, accumulator, element) => combine(accumulator, element),
  );

  /// Folds the elements step by step, starting with [initial] and handing
  /// [combine] the index of every element.
  ///
  /// Returns [initial] followed by every intermediate value, lazily.
  @useResult
  Iterable<R> runningFoldIndexed<R>(
    R initial,
    R Function(int index, R accumulator, T element) combine,
  ) sync* {
    var accumulator = initial;
    yield accumulator;
    var index = 0;
    for (final element in this) {
      accumulator = combine(index++, accumulator, element);
      yield accumulator;
    }
  }

  /// Reduces the elements step by step, starting with the first one.
  ///
  /// Returns every intermediate value, lazily; none for no elements.
  @useResult
  Iterable<T> runningReduce(T Function(T accumulator, T element) combine) =>
      runningReduceIndexed(
        (_, accumulator, element) => combine(accumulator, element),
      );

  /// Reduces the elements step by step, starting with the first one and
  /// handing [combine] the index of every further element.
  ///
  /// Returns every intermediate value, lazily; none for no elements.
  @useResult
  Iterable<T> runningReduceIndexed(
    T Function(int index, T accumulator, T element) combine,
  ) sync* {
    final Iterator<T> elements = iterator;
    if (!elements.moveNext()) {
      return;
    }
    T accumulator = elements.current;
    yield accumulator;
    for (var index = 1; elements.moveNext(); index++) {
      accumulator = combine(index, accumulator, elements.current);
      yield accumulator;
    }
  }

  /// Reduces the elements, starting with the first one.
  ///
  /// Returns the reduced value, or `null` if there are no elements.
  @useResult
  T? reduceOrNull(T Function(T accumulator, T element) combine) =>
      runningReduce(combine).lastOrNull;

  /// Reduces the elements, starting with the first one and handing
  /// [combine] the index of every further element.
  ///
  /// Returns the reduced value, or `null` if there are no elements.
  @useResult
  T? reduceIndexedOrNull(
    T Function(int index, T accumulator, T element) combine,
  ) => runningReduceIndexed(combine).lastOrNull;
}
