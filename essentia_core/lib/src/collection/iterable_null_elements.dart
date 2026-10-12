/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// Kotlin's `requireNoNulls` for an iterable of nullable elements.
extension IterableNullElements<T extends Object> on Iterable<T?> {
  /// Passes on the elements lazily, typed as present.
  ///
  /// Kotlin's `requireNoNulls`, except that the check happens as each
  /// element is reached rather than up front.
  ///
  /// Returns the elements as non-nullable ones.
  ///
  /// Throws an [ArgumentError] when a `null` element is reached.
  @useResult
  Iterable<T> requireNoNulls() => map(
    (element) => element ?? (throw ArgumentError('A null element was found.')),
  );
}
