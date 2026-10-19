/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// The distinctness operators for streams.
extension StreamDistinctness<T> on Stream<T> {
  /// Drops every element whose key, computed by [keyOf], equals the key of
  /// the element emitted before it.
  ///
  /// Only consecutive repetitions are dropped; a key that comes back later
  /// is emitted again.
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  Stream<T> distinctUntilChangedBy<K>(K Function(T element) keyOf) =>
      distinct((previous, next) => keyOf(previous) == keyOf(next));
}
