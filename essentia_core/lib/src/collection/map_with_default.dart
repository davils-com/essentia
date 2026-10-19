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

/// A read only view of a map whose [getValue] derives the value of a
/// missing key from a default.
///
/// Only [getValue] applies the default; the index operator
/// still returns `null` for a missing key.
final class MapWithDefault<K, V> extends UnmodifiableMapView<K, V> {
  /// Creates the view of [map] that derives the value of a missing key
  /// with [defaultOf].
  MapWithDefault(super.map, V Function(K key) defaultOf)
    : _defaultOf = ((key) => defaultOf(key as K));

  /// Derives the value of a missing key.
  final V Function(Object? key) _defaultOf;

  /// The value stored under [key].
  ///
  /// Returns the value, or the default for [key] when it is missing.
  @useResult
  V getValue(K key) => containsKey(key) ? this[key] as V : _defaultOf(key);
}
