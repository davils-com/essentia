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

/// The elements of a source together with the key of the group each one
/// belongs to, waiting for an operation that combines every group at once.
///
/// A grouping is returned by `groupingBy`. The source is read again by every
/// operation, and only when the operation runs.
@immutable
final class Grouping<T, K> {
  /// Groups the elements of [source] by the key [keyOf] computes for each.
  Grouping(Iterable<T> source, K Function(T element) keyOf)
    : _entries = source.map((element) => (keyOf(element), element));

  /// Every element paired with its key, in the order of the source.
  final Iterable<(K, T)> _entries;

  /// Counts the elements of every group.
  ///
  /// Returns an unmodifiable map from every key to the size of its group.
  @useResult
  Map<K, int> eachCount() => fold(0, (count, _) => count + 1);

  /// Folds the elements of every group, starting each group with
  /// [initial] and combining it with every element in turn.
  ///
  /// Returns an unmodifiable map from every key to its folded value.
  @useResult
  Map<K, R> fold<R>(R initial, R Function(R accumulator, T element) combine) {
    final folded = <K, R>{};
    for (final (K key, T element) in _entries) {
      folded[key] = combine(
        folded.containsKey(key) ? folded[key] as R : initial,
        element,
      );
    }
    return Map<K, R>.unmodifiable(folded);
  }

  /// Reduces the elements of every group, starting each group with its
  /// first element and combining it with every element after it.
  ///
  /// Returns an unmodifiable map from every key to its reduced value.
  @useResult
  Map<K, T> reduce(T Function(K key, T accumulator, T element) combine) {
    final reduced = <K, T>{};
    for (final (K key, T element) in _entries) {
      reduced[key] = reduced.containsKey(key)
          ? combine(key, reduced[key] as T, element)
          : element;
    }
    return Map<K, T>.unmodifiable(reduced);
  }

  /// Aggregates the elements of every group with [operation], which
  /// receives the key, the value so far, `null` for the first element of a
  /// group, and the element.
  ///
  /// Returns an unmodifiable map from every key to its aggregated value.
  @useResult
  Map<K, R> aggregate<R extends Object>(
    R Function(K key, R? accumulator, T element) operation,
  ) {
    final aggregated = <K, R>{};
    for (final (K key, T element) in _entries) {
      aggregated[key] = operation(key, aggregated[key], element);
    }
    return Map<K, R>.unmodifiable(aggregated);
  }
}
