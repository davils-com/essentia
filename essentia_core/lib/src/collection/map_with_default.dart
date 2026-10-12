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

/// A read only view of a map whose [getValue] derives the value of a
/// missing key from a default, Kotlin's `MapWithDefault`.
///
/// As in Kotlin, only [getValue] applies the default; the index operator
/// still returns `null` for a missing key.
final class MapWithDefault<K, V> extends UnmodifiableMapView<K, V> {
  /// Creates the view of [map] that derives the value of a missing key
  /// with [defaultOf].
  MapWithDefault(super.map, V Function(K key) defaultOf)
    : _defaultOf = ((key) => defaultOf(key as K));

  /// Derives the value of a missing key.
  final V Function(Object? key) _defaultOf;

  /// The value stored under [key], Kotlin's `getValue`.
  ///
  /// Returns the value, or the default for [key] when it is missing.
  @useResult
  V getValue(K key) => containsKey(key) ? this[key] as V : _defaultOf(key);
}
