/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// A sink that collects what it is given into [values].
final class CollectingSink<T> implements Sink<T> {
  /// Creates the sink that collects into [values].
  CollectingSink(this.values);

  /// What the sink was given.
  final List<T> values;

  /// Collects [data].
  @override
  void add(T data) {
    values.add(data);
  }

  /// Whether the sink was closed.
  var closed = false;

  /// Remembers that the sink was closed.
  @override
  void close() {
    closed = true;
  }
}
