/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Treats a missing map as an empty one, Kotlin's `isNullOrEmpty` and
/// `orEmpty`.
extension NullableMap<K, V> on Map<K, V>? {
  /// Whether the map is `null` or has no entries, Kotlin's
  /// `isNullOrEmpty`.
  bool get isNullOrEmpty => this?.isEmpty ?? true;

  /// The map itself, or an empty one when it is `null`, Kotlin's
  /// `orEmpty`.
  ///
  /// Returns this map, or an unmodifiable empty map.
  @useResult
  Map<K, V> orEmpty() => this ?? Map<K, V>.unmodifiable(<K, V>{});
}
