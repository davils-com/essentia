/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Transforms and filters the entries of a map, Kotlin's `mapKeys`,
/// `mapValues`, `mapNotNull`, `filter`, `filterNot`, `filterKeys`,
/// `filterValues` and `toList`.
extension MapTransformation<K, V> on Map<K, V> {
  /// The entries with their keys replaced by what [transform] returns,
  /// Kotlin's `mapKeys`.
  ///
  /// Returns an unmodifiable map; when two keys transform to the same key,
  /// the later entry wins.
  @useResult
  Map<R, V> mapKeys<R>(R Function(K key, V value) transform) =>
      Map<R, V>.unmodifiable(<R, V>{
        for (final MapEntry(:key, :value) in entries)
          transform(key, value): value,
      });

  /// The entries with their values replaced by what [transform] returns,
  /// Kotlin's `mapValues`.
  ///
  /// Returns an unmodifiable map with the same keys.
  @useResult
  Map<K, R> mapValues<R>(R Function(K key, V value) transform) =>
      Map<K, R>.unmodifiable(<K, R>{
        for (final MapEntry(:key, :value) in entries)
          key: transform(key, value),
      });

  /// What [transform] returns for each entry, without the `null`s,
  /// Kotlin's `mapNotNull`.
  ///
  /// Returns an unmodifiable list in the order of the entries.
  @useResult
  List<R> mapNotNull<R extends Object>(R? Function(K key, V value) transform) =>
      List<R>.unmodifiable(
        entries.map((entry) => transform(entry.key, entry.value)).nonNulls,
      );

  /// The entries that satisfy [predicate], Kotlin's `filter`.
  ///
  /// Returns an unmodifiable map in the order of this map.
  @useResult
  Map<K, V> where(bool Function(K key, V value) predicate) =>
      Map<K, V>.unmodifiable(<K, V>{
        for (final MapEntry(:key, :value) in entries)
          if (predicate(key, value)) key: value,
      });

  /// The entries that do not satisfy [predicate], Kotlin's `filterNot`.
  ///
  /// Returns an unmodifiable map in the order of this map.
  @useResult
  Map<K, V> whereNot(bool Function(K key, V value) predicate) =>
      where((key, value) => !predicate(key, value));

  /// The entries whose key satisfies [predicate], Kotlin's `filterKeys`.
  ///
  /// Returns an unmodifiable map in the order of this map.
  @useResult
  Map<K, V> whereKeys(bool Function(K key) predicate) =>
      where((key, _) => predicate(key));

  /// The entries whose value satisfies [predicate], Kotlin's
  /// `filterValues`.
  ///
  /// Returns an unmodifiable map in the order of this map.
  @useResult
  Map<K, V> whereValues(bool Function(V value) predicate) =>
      where((_, value) => predicate(value));

  /// The entries as key and value records, Kotlin's `toList` of pairs.
  ///
  /// Returns an unmodifiable list in the order of this map.
  @useResult
  List<(K, V)> toRecords() => List<(K, V)>.unmodifiable(
    entries.map((entry) => (entry.key, entry.value)),
  );
}
