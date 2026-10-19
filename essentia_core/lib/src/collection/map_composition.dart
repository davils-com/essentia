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

import 'dart:collection';

import 'package:meta/meta.dart';

/// Derives new maps from a map.
extension MapComposition<K, V> on Map<K, V> {
  /// The entries of this map without [key].
  ///
  /// Returns an unmodifiable map in the order of this map.
  @useResult
  Map<K, V> minusKey(K key) => minusKeys(<K>[key]);

  /// The entries of this map without any of [keys].
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

  /// The entries of this map ordered by their keys.
  ///
  /// The keys are ordered by [compare], or by their natural order when it
  /// is not given.
  ///
  /// Returns an unmodifiable sorted map.
  @useResult
  Map<K, V> toSortedMap([Comparator<K>? compare]) =>
      UnmodifiableMapView<K, V>(SplayTreeMap<K, V>.of(this, compare));

  /// This map, or the one [fallback] creates when this map is empty.
  ///
  /// Returns an unmodifiable copy of this map, or the result of
  /// [fallback].
  @useResult
  Map<K, V> ifEmpty(Map<K, V> Function() fallback) =>
      isEmpty ? fallback() : Map<K, V>.unmodifiable(this);
}
