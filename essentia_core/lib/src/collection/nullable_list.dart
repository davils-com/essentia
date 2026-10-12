/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Kotlin's `orEmpty` for a list that may be absent.
extension NullableList<T> on List<T>? {
  /// Replaces an absent list with an empty one that cannot grow.
  ///
  /// Kotlin's `orEmpty`.
  ///
  /// Returns this list, or an empty, fixed-length one if it is absent.
  @useResult
  List<T> orEmpty() => this ?? List<T>.empty();
}
