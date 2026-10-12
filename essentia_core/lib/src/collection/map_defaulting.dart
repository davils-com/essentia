/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/collection/map_with_default.dart';
import 'package:meta/meta.dart';

/// Gives a map a default for missing keys, Kotlin's `withDefault`.
extension MapDefaulting<K, V> on Map<K, V> {
  /// A read only view of this map whose `getValue` derives the value of
  /// a missing key from [defaultOf], Kotlin's `withDefault`.
  ///
  /// Returns the view.
  @useResult
  MapWithDefault<K, V> withDefault(V Function(K key) defaultOf) =>
      MapWithDefault<K, V>(this, defaultOf);
}
