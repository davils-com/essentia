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

/// Reads the values of a map by key.
extension MapAccess<K, V> on Map<K, V> {
  /// The value stored under [key], or a fallback when it is missing.
  ///
  /// Unlike `this[key] ?? fallback()`, a `null` stored under a present
  /// key is kept.
  ///
  /// Returns the value, or what [fallback] returns when [key] is missing.
  @useResult
  V getOrElse(K key, V Function() fallback) =>
      containsKey(key) ? this[key] as V : fallback();

  /// The value stored under [key], which must exist.
  ///
  /// Returns the value.
  ///
  /// Throws a [StateError] if [key] is missing.
  @useResult
  V getValue(K key) => getOrElse(
    key,
    () => throw StateError('The key $key is missing in the map.'),
  );
}
