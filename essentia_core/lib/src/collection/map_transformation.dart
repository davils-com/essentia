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

/// Transforms and filters the entries of a map.
extension MapTransformation<K, V> on Map<K, V> {
  /// The entries with their keys replaced by what [transform] returns.
  ///
  /// Returns an unmodifiable map; when two keys transform to the same key,
  /// the later entry wins.
  @useResult
  Map<R, V> mapKeys<R>(R Function(K key, V value) transform) =>
      Map<R, V>.unmodifiable(<R, V>{
        for (final MapEntry(:key, :value) in entries)
          transform(key, value): value,
      });

  /// The entries with their values replaced by what [transform] returns.
  ///
  /// Returns an unmodifiable map with the same keys.
  @useResult
  Map<K, R> mapValues<R>(R Function(K key, V value) transform) =>
      Map<K, R>.unmodifiable(<K, R>{
        for (final MapEntry(:key, :value) in entries)
          key: transform(key, value),
      });

  /// What [transform] returns for each entry, without the `null`s.
  ///
  /// Returns an unmodifiable list in the order of the entries.
  @useResult
  List<R> mapNotNull<R extends Object>(R? Function(K key, V value) transform) =>
      List<R>.unmodifiable(
        entries.map((entry) => transform(entry.key, entry.value)).nonNulls,
      );

  /// The entries that satisfy [predicate].
  ///
  /// Returns an unmodifiable map in the order of this map.
  @useResult
  Map<K, V> where(bool Function(K key, V value) predicate) =>
      Map<K, V>.unmodifiable(<K, V>{
        for (final MapEntry(:key, :value) in entries)
          if (predicate(key, value)) key: value,
      });

  /// The entries that do not satisfy [predicate].
  ///
  /// Returns an unmodifiable map in the order of this map.
  @useResult
  Map<K, V> whereNot(bool Function(K key, V value) predicate) =>
      where((key, value) => !predicate(key, value));

  /// The entries whose key satisfies [predicate].
  ///
  /// Returns an unmodifiable map in the order of this map.
  @useResult
  Map<K, V> whereKeys(bool Function(K key) predicate) =>
      where((key, _) => predicate(key));

  /// The entries whose value satisfies [predicate].
  ///
  /// Returns an unmodifiable map in the order of this map.
  @useResult
  Map<K, V> whereValues(bool Function(V value) predicate) =>
      where((_, value) => predicate(value));

  /// The entries as key and value records.
  ///
  /// Returns an unmodifiable list in the order of this map.
  @useResult
  List<(K, V)> toRecords() => List<(K, V)>.unmodifiable(
    entries.map((entry) => (entry.key, entry.value)),
  );
}
