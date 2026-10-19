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

/// Orders [left] before [right] when it is smaller.
///
/// Returns the result of comparing [left] to [right].
int _ascending(Comparable<Object> left, Comparable<Object> right) =>
    left.compareTo(right);

/// Orders [left] before [right] when it is larger.
///
/// Returns the result of comparing [right] to [left].
int _descending(Comparable<Object> left, Comparable<Object> right) =>
    right.compareTo(left);

/// Refuses to find an extreme of a source without elements.
///
/// Throws a [StateError], always.
Never _noElement() => throw StateError('No element');

/// Turns [comparator] around, so that the largest element becomes the
/// smallest.
///
/// Returns the reversed comparator.
Comparator<T> _reversed<T>(Comparator<T> comparator) =>
    (left, right) => comparator(right, left);

/// Selects extremes of an iterable: the element with the largest or
/// smallest key, the largest or smallest selected value, and the largest or
/// smallest element by a comparator.
///
/// Of several elements that tie, the first one wins.
extension IterableExtremes<T> on Iterable<T> {
  /// Finds the first element with the largest key [keyOf] computes.
  ///
  /// Returns that element.
  ///
  /// Throws a [StateError] if there are no elements.
  @useResult
  T maxBy<K extends Comparable<Object>>(K Function(T element) keyOf) =>
      (_extreme(keyOf, _ascending) ?? _noElement()).element;

  /// Finds the first element with the largest key [keyOf] computes.
  ///
  /// Returns that element, or `null` if there are no elements.
  @useResult
  T? maxByOrNull<K extends Comparable<Object>>(K Function(T element) keyOf) =>
      _extreme(keyOf, _ascending)?.element;

  /// Finds the first element with the smallest key [keyOf] computes.
  ///
  /// Returns that element.
  ///
  /// Throws a [StateError] if there are no elements.
  @useResult
  T minBy<K extends Comparable<Object>>(K Function(T element) keyOf) =>
      (_extreme(keyOf, _descending) ?? _noElement()).element;

  /// Finds the first element with the smallest key [keyOf] computes.
  ///
  /// Returns that element, or `null` if there are no elements.
  @useResult
  T? minByOrNull<K extends Comparable<Object>>(K Function(T element) keyOf) =>
      _extreme(keyOf, _descending)?.element;

  /// Finds the largest value [selector] computes for an element.
  ///
  /// Returns that value.
  ///
  /// Throws a [StateError] if there are no elements.
  @useResult
  K maxOf<K extends Comparable<Object>>(K Function(T element) selector) =>
      (_extreme(selector, _ascending) ?? _noElement()).key;

  /// Finds the largest value [selector] computes for an element.
  ///
  /// Returns that value, or `null` if there are no elements.
  @useResult
  K? maxOfOrNull<K extends Comparable<Object>>(
    K Function(T element) selector,
  ) => _extreme(selector, _ascending)?.key;

  /// Finds the smallest value [selector] computes for an element.
  ///
  /// Returns that value.
  ///
  /// Throws a [StateError] if there are no elements.
  @useResult
  K minOf<K extends Comparable<Object>>(K Function(T element) selector) =>
      (_extreme(selector, _descending) ?? _noElement()).key;

  /// Finds the smallest value [selector] computes for an element.
  ///
  /// Returns that value, or `null` if there are no elements.
  @useResult
  K? minOfOrNull<K extends Comparable<Object>>(
    K Function(T element) selector,
  ) => _extreme(selector, _descending)?.key;

  /// Finds the first element that [comparator] orders after every other.
  ///
  /// Returns that element.
  ///
  /// Throws a [StateError] if there are no elements.
  @useResult
  T maxWith(Comparator<T> comparator) =>
      (_extreme((element) => element, comparator) ?? _noElement()).element;

  /// Finds the first element that [comparator] orders after every other.
  ///
  /// Returns that element, or `null` if there are no elements.
  @useResult
  T? maxWithOrNull(Comparator<T> comparator) =>
      _extreme((element) => element, comparator)?.element;

  /// Finds the first element that [comparator] orders before every other.
  ///
  /// Returns that element.
  ///
  /// Throws a [StateError] if there are no elements.
  @useResult
  T minWith(Comparator<T> comparator) => maxWith(_reversed(comparator));

  /// Finds the first element that [comparator] orders before every other.
  ///
  /// Returns that element, or `null` if there are no elements.
  @useResult
  T? minWithOrNull(Comparator<T> comparator) =>
      maxWithOrNull(_reversed(comparator));

  /// Walks the elements once and keeps the first one whose key, computed
  /// by [keyOf], [order] places after every other key.
  ///
  /// Returns that element together with its key, or `null` if there are
  /// no elements.
  ({T element, K key})? _extreme<K>(
    K Function(T element) keyOf,
    Comparator<K> order,
  ) {
    final Iterator<T> elements = iterator;
    if (!elements.moveNext()) {
      return null;
    }
    ({T element, K key}) best = (
      element: elements.current,
      key: keyOf(elements.current),
    );
    while (elements.moveNext()) {
      final T candidate = elements.current;
      final K key = keyOf(candidate);
      if (order(key, best.key) > 0) {
        best = (element: candidate, key: key);
      }
    }
    return best;
  }
}
