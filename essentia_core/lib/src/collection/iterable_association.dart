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

import 'package:essentia_core/src/collection/grouping.dart';
import 'package:meta/meta.dart';

/// Associates the elements of an iterable: turns them into maps,
/// partitions and groupings.
extension IterableAssociation<T> on Iterable<T> {
  /// Builds a map from the key and value pairs [transform] makes of every
  /// element; a later pair replaces an earlier one with the same key.
  ///
  /// Returns an unmodifiable map in the order of the elements.
  @useResult
  Map<K, V> associate<K, V>((K, V) Function(T element) transform) =>
      Map<K, V>.unmodifiable(<K, V>{
        for (final (key, value) in map(transform)) key: value,
      });

  /// Builds a map from every element to the value [valueOf] computes for
  /// it.
  ///
  /// Returns an unmodifiable map in the order of the elements.
  @useResult
  Map<T, V> associateWith<V>(V Function(T element) valueOf) =>
      Map<T, V>.unmodifiable(<T, V>{
        for (final element in this) element: valueOf(element),
      });

  /// Splits the elements into those [predicate] accepts and the rest.
  ///
  /// Returns both parts as unmodifiable lists in the order of the
  /// elements.
  @useResult
  ({List<T> matched, List<T> unmatched}) partitionWhere(
    bool Function(T element) predicate,
  ) {
    final matched = <T>[];
    final unmatched = <T>[];
    for (final element in this) {
      (predicate(element) ? matched : unmatched).add(element);
    }
    return (
      matched: List<T>.unmodifiable(matched),
      unmatched: List<T>.unmodifiable(unmatched),
    );
  }

  /// Groups the elements by the key [keyOf] computes for each, for an
  /// operation that combines every group at once.
  ///
  /// Returns the [Grouping] of these elements.
  @useResult
  Grouping<T, K> groupingBy<K>(K Function(T element) keyOf) =>
      Grouping<T, K>(this, keyOf);
}
