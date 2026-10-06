/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:collection';

import 'package:meta/meta.dart';

/// Derives new maps from a map, Kotlin's `minus`, `toSortedMap` and
/// `ifEmpty`.
extension MapComposition<K, V> on Map<K, V> {
  /// The entries of this map without [key], Kotlin's `minus`.
  ///
  /// Returns an unmodifiable map in the order of this map.
  @useResult
  Map<K, V> minusKey(K key) => minusKeys(<K>[key]);

  /// The entries of this map without any of [keys], Kotlin's `minus`.
  ///
  /// Returns an unmodifiable map in the order of this map.
  @useResult
  Map<K, V> minusKeys(Iterable<K> keys) {
    final Set<K> removed = keys.toSet();
    return Map<K, V>.unmodifiable(<K, V>{
      for (final MapEntry(:key, :value) in entries)
        if (!removed.contains(key)) key: value,
    });
  }

  /// The entries of this map ordered by their keys, Kotlin's
  /// `toSortedMap`.
  ///
  /// The keys are ordered by [compare], or by their natural order when it
  /// is not given.
  ///
  /// Returns an unmodifiable sorted map.
  @useResult
  Map<K, V> toSortedMap([Comparator<K>? compare]) =>
      UnmodifiableMapView<K, V>(SplayTreeMap<K, V>.of(this, compare));

  /// This map, or the one [fallback] creates when this map is empty,
  /// Kotlin's `ifEmpty`.
  ///
  /// Returns an unmodifiable copy of this map, or the result of
  /// [fallback].
  @useResult
  Map<K, V> ifEmpty(Map<K, V> Function() fallback) =>
      isEmpty ? fallback() : Map<K, V>.unmodifiable(this);
}
