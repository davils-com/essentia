/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// The elements of a source together with the key of the group each one
/// belongs to, waiting for an operation that combines every group at once.
///
/// Kotlin's `Grouping`, as returned by `groupingBy`. The source is read
/// again by every operation, and only when the operation runs.
@immutable
final class Grouping<T, K> {
  /// Groups the elements of [source] by the key [keyOf] computes for each.
  Grouping(Iterable<T> source, K Function(T element) keyOf)
    : _entries = source.map((element) => (keyOf(element), element));

  /// Every element paired with its key, in the order of the source.
  final Iterable<(K, T)> _entries;

  /// Counts the elements of every group.
  ///
  /// Kotlin's `Grouping.eachCount`.
  ///
  /// Returns an unmodifiable map from every key to the size of its group.
  @useResult
  Map<K, int> eachCount() => fold(0, (count, _) => count + 1);

  /// Folds the elements of every group, starting each group with
  /// [initial] and combining it with every element in turn.
  ///
  /// Kotlin's `Grouping.fold`.
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
  /// Kotlin's `Grouping.reduce`.
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
  /// Kotlin's `Grouping.aggregate`.
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
