/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Kotlin's running folds and reductions, and the reductions that tolerate
/// a source without elements.
extension IterableAccumulation<T> on Iterable<T> {
  /// Folds the elements step by step, starting with [initial].
  ///
  /// Kotlin's `runningFold`.
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
  /// Kotlin's `runningFoldIndexed`.
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
  /// Kotlin's `runningReduce`.
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
  /// Kotlin's `runningReduceIndexed`.
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
  /// Kotlin's `reduceOrNull`.
  ///
  /// Returns the reduced value, or `null` if there are no elements.
  @useResult
  T? reduceOrNull(T Function(T accumulator, T element) combine) =>
      runningReduce(combine).lastOrNull;

  /// Reduces the elements, starting with the first one and handing
  /// [combine] the index of every further element.
  ///
  /// Kotlin's `reduceIndexedOrNull`.
  ///
  /// Returns the reduced value, or `null` if there are no elements.
  @useResult
  T? reduceIndexedOrNull(
    T Function(int index, T accumulator, T element) combine,
  ) => runningReduceIndexed(combine).lastOrNull;
}
