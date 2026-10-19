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

/// Folds and reductions from the right for a list.
extension ListFolding<T> on List<T> {
  /// Folds the elements from the last to the first, starting with
  /// [initial].
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
  /// Returns the reduced value, or `null` if the list is empty.
  @useResult
  T? reduceRightOrNull(T Function(T element, T accumulator) combine) =>
      isEmpty ? null : reduceRight(combine);
}
