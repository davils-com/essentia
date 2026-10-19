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

import 'package:essentia_core/src/comparison/comparison_dsl.dart';
import 'package:meta/meta.dart';

/// Breaks the ties of a comparator with further keys or comparators.
extension ComparatorChaining<T> on Comparator<T> {
  /// Orders the elements this comparator considers equal by the key
  /// [keyOf] selects, ascending.
  ///
  /// Returns the chained comparator.
  @useResult
  Comparator<T> thenBy<K extends Comparable<Object>>(
    K Function(T element) keyOf,
  ) => _then(compareBy(keyOf));

  /// Orders the elements this comparator considers equal by the key
  /// [keyOf] selects, descending.
  ///
  /// Returns the chained comparator.
  @useResult
  Comparator<T> thenByDescending<K extends Comparable<Object>>(
    K Function(T element) keyOf,
  ) => _then(compareByDescending(keyOf));

  /// Orders the elements this comparator considers equal by the reverse
  /// of [tieBreaker].
  ///
  /// Returns the chained comparator.
  @useResult
  Comparator<T> thenDescending(Comparator<T> tieBreaker) =>
      _then((left, right) => tieBreaker(right, left));

  /// Orders by this comparator first and by [tieBreaker] where this
  /// comparator finds a tie.
  ///
  /// Returns the chained comparator.
  Comparator<T> _then(Comparator<T> tieBreaker) => (left, right) {
    final int order = this(left, right);
    return order == 0 ? tieBreaker(left, right) : order;
  };
}
