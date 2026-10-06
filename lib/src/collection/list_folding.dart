/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Kotlin's folds and reductions from the right for a list.
extension ListFolding<T> on List<T> {
  /// Folds the elements from the last to the first, starting with
  /// [initial].
  ///
  /// Kotlin's `foldRight`.
  ///
  /// Returns the folded value, [initial] for no elements.
  @useResult
  R foldRight<R>(R initial, R Function(T element, R accumulator) combine) =>
      foldRightIndexed(
        initial,
        (_, element, accumulator) => combine(element, accumulator),
      );

  /// Folds the elements from the last to the first, starting with
  /// [initial] and handing [combine] the index of every element.
  ///
  /// Kotlin's `foldRightIndexed`.
  ///
  /// Returns the folded value, [initial] for no elements.
  @useResult
  R foldRightIndexed<R>(
    R initial,
    R Function(int index, T element, R accumulator) combine,
  ) {
    var accumulator = initial;
    for (int index = length - 1; index >= 0; index--) {
      accumulator = combine(index, this[index], accumulator);
    }
    return accumulator;
  }

  /// Reduces the elements from the last to the first, starting with the
  /// last one.
  ///
  /// Kotlin's `reduceRight`.
  ///
  /// Returns the reduced value.
  ///
  /// Throws a [StateError] if the list is empty.
  @useResult
  T reduceRight(T Function(T element, T accumulator) combine) {
    if (isEmpty) {
      throw StateError('No element');
    }
    return sublist(0, length - 1).foldRight(last, combine);
  }

  /// Reduces the elements from the last to the first, starting with the
  /// last one.
  ///
  /// Kotlin's `reduceRightOrNull`.
  ///
  /// Returns the reduced value, or `null` if the list is empty.
  @useResult
  T? reduceRightOrNull(T Function(T element, T accumulator) combine) =>
      isEmpty ? null : reduceRight(combine);
}
