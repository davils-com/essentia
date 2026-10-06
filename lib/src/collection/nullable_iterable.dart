/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Kotlin's `isNullOrEmpty` and `orEmpty` for an iterable that may be
/// absent.
extension NullableIterable<T> on Iterable<T>? {
  /// Whether this iterable is absent or has no elements.
  ///
  /// Kotlin's `isNullOrEmpty`.
  bool get isNullOrEmpty => this?.isEmpty ?? true;

  /// Replaces an absent iterable with an empty one.
  ///
  /// Kotlin's `orEmpty`.
  ///
  /// Returns this iterable, or an empty one if it is absent.
  @useResult
  Iterable<T> orEmpty() => this ?? Iterable<T>.empty();
}
