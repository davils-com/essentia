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

/// Aggregates the elements of an iterable: sums, counts, indexes and the
/// first value a transformation produces.
extension IterableAggregation<T> on Iterable<T> {
  /// Adds up the integer [selector] computes for every element.
  ///
  /// Returns the sum, zero for no elements.
  @useResult
  int sumOfInt(int Function(T element) selector) =>
      fold(0, (sum, element) => sum + selector(element));

  /// Adds up the double [selector] computes for every element.
  ///
  /// Returns the sum, zero for no elements.
  @useResult
  double sumOfDouble(double Function(T element) selector) =>
      fold(0, (sum, element) => sum + selector(element));

  /// Adds up the duration [selector] computes for every element.
  ///
  /// Returns the sum, [Duration.zero] for no elements.
  @useResult
  Duration sumOfDuration(Duration Function(T element) selector) =>
      fold(Duration.zero, (sum, element) => sum + selector(element));

  /// Counts the elements [predicate] accepts.
  ///
  /// Returns the number of accepted elements.
  @useResult
  int countWhere(bool Function(T element) predicate) =>
      fold(0, (count, element) => predicate(element) ? count + 1 : count);

  /// Finds the first element [predicate] accepts.
  ///
  /// Returns its index, or `-1` when no element is accepted.
  @useResult
  int indexOfFirst(bool Function(T element) predicate) {
    for (final (int index, T element) in indexed) {
      if (predicate(element)) {
        return index;
      }
    }
    return -1;
  }

  /// Finds the last element [predicate] accepts.
  ///
  /// Returns its index, or `-1` when no element is accepted.
  @useResult
  int indexOfLast(bool Function(T element) predicate) {
    var found = -1;
    for (final (int index, T element) in indexed) {
      if (predicate(element)) {
        found = index;
      }
    }
    return found;
  }

  /// Transforms the elements in order until [transform] returns a value.
  ///
  /// Returns the first value that is not `null`.
  ///
  /// Throws a [StateError] if every element is transformed into `null`.
  @useResult
  R firstNotNullOf<R extends Object>(R? Function(T element) transform) =>
      firstNotNullOfOrNull(transform) ??
      (throw StateError('No element was transformed into a value.'));

  /// Transforms the elements in order until [transform] returns a value.
  ///
  /// Returns the first value that is not `null`, or `null` if there is
  /// none.
  @useResult
  R? firstNotNullOfOrNull<R extends Object>(R? Function(T element) transform) =>
      map(transform).nonNulls.firstOrNull;
}
