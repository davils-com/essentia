/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/collection/grouping.dart';
import 'package:meta/meta.dart';

/// Kotlin's association functions: turning the elements of an iterable
/// into maps, partitions and groupings.
extension IterableAssociation<T> on Iterable<T> {
  /// Builds a map from the key and value pairs [transform] makes of every
  /// element; a later pair replaces an earlier one with the same key.
  ///
  /// Kotlin's `associate`.
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
  /// Kotlin's `associateWith`.
  ///
  /// Returns an unmodifiable map in the order of the elements.
  @useResult
  Map<T, V> associateWith<V>(V Function(T element) valueOf) =>
      Map<T, V>.unmodifiable(<T, V>{
        for (final element in this) element: valueOf(element),
      });

  /// Splits the elements into those [predicate] accepts and the rest.
  ///
  /// Kotlin's `partition`.
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
  /// Kotlin's `groupingBy`.
  ///
  /// Returns the [Grouping] of these elements.
  @useResult
  Grouping<T, K> groupingBy<K>(K Function(T element) keyOf) =>
      Grouping<T, K>(this, keyOf);
}
