/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Reads the values of a map by key, Kotlin's `getOrElse` and
/// `getValue`.
extension MapAccess<K, V> on Map<K, V> {
  /// The value stored under [key], Kotlin's `getOrElse`.
  ///
  /// Unlike `this[key] ?? fallback()`, a `null` stored under a present
  /// key is kept.
  ///
  /// Returns the value, or what [fallback] returns when [key] is missing.
  @useResult
  V getOrElse(K key, V Function() fallback) =>
      containsKey(key) ? this[key] as V : fallback();

  /// The value stored under [key], which must exist, Kotlin's
  /// `getValue`.
  ///
  /// Returns the value.
  ///
  /// Throws a [StateError] if [key] is missing, where Kotlin throws a
  /// `NoSuchElementException`.
  @useResult
  V getValue(K key) => getOrElse(
    key,
    () => throw StateError('The key $key is missing in the map.'),
  );
}
