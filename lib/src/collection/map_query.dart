/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Asks questions about the entries of a map, Kotlin's `any`, `all`,
/// `none` and `count`.
extension MapQuery<K, V> on Map<K, V> {
  /// Whether at least one entry satisfies [predicate], Kotlin's `any`.
  ///
  /// Returns `false` for an empty map.
  @useResult
  bool any(bool Function(K key, V value) predicate) =>
      entries.any((entry) => predicate(entry.key, entry.value));

  /// Whether every entry satisfies [predicate], Kotlin's `all`.
  ///
  /// Returns `true` for an empty map.
  @useResult
  bool every(bool Function(K key, V value) predicate) =>
      entries.every((entry) => predicate(entry.key, entry.value));

  /// Whether no entry satisfies [predicate], Kotlin's `none`.
  ///
  /// Returns `true` for an empty map.
  @useResult
  bool none(bool Function(K key, V value) predicate) => !any(predicate);

  /// The number of entries that satisfy [predicate], Kotlin's `count`.
  ///
  /// Returns the count.
  @useResult
  int countWhere(bool Function(K key, V value) predicate) =>
      entries.where((entry) => predicate(entry.key, entry.value)).length;
}
