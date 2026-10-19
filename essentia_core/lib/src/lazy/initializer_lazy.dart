/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/lazy/lazy.dart';
import 'package:meta/meta.dart';

/// The [Lazy] that `lazy` creates: it runs its initializer on the first read
/// and keeps the result.
@internal
final class InitializerLazy<T> implements Lazy<T> {
  /// Creates the [Lazy] that [initializer] computes on the first read.
  InitializerLazy(T Function() initializer) : _initializer = initializer;

  /// The function that computes the value; `null` once it has.
  T Function()? _initializer;

  /// The computed value, meaningful only once [isInitialized] holds.
  T? _value;

  /// Whether the initializer is running, to refuse a read from inside it.
  var _initializing = false;

  /// Whether the value has been computed.
  @override
  bool get isInitialized => _initializer == null;

  /// The value, computed on the first read.
  ///
  /// Throws a [StateError] if it is read from inside its own initializer,
  /// and whatever the initializer throws, in which case the next read runs
  /// the initializer again.
  @override
  T get value {
    final T Function()? initializer = _initializer;
    if (initializer == null) {
      return _value as T;
    }
    if (_initializing) {
      throw StateError('A lazy value was read while it was being computed');
    }
    _initializing = true;
    try {
      final T computed = initializer();
      _value = computed;
      _initializer = null;
      return computed;
    } finally {
      _initializing = false;
    }
  }

  /// Renders the value once it is computed, and
  /// `Lazy value not initialized yet.` before.
  @override
  String toString() {
    if (isInitialized) {
      return '$_value';
    }
    return 'Lazy value not initialized yet.';
  }
}
