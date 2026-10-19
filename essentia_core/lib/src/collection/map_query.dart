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

/// Asks questions about the entries of a map.
extension MapQuery<K, V> on Map<K, V> {
  /// Whether at least one entry satisfies [predicate].
  ///
  /// Returns `false` for an empty map.
  @useResult
  bool any(bool Function(K key, V value) predicate) =>
      entries.any((entry) => predicate(entry.key, entry.value));

  /// Whether every entry satisfies [predicate].
  ///
  /// Returns `true` for an empty map.
  @useResult
  bool every(bool Function(K key, V value) predicate) =>
      entries.every((entry) => predicate(entry.key, entry.value));

  /// Whether no entry satisfies [predicate].
  ///
  /// Returns `true` for an empty map.
  @useResult
  bool none(bool Function(K key, V value) predicate) => !any(predicate);

  /// The number of entries that satisfy [predicate].
  ///
  /// Returns the count.
  @useResult
  int countWhere(bool Function(K key, V value) predicate) =>
      entries.where((entry) => predicate(entry.key, entry.value)).length;
}
