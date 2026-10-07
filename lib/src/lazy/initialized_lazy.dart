/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/lazy/lazy.dart';
import 'package:meta/meta.dart';

/// The [Lazy] that `lazyOf` creates around a value that is already known,
/// Kotlin's `InitializedLazyImpl`.
@immutable
@internal
final class InitializedLazy<T> implements Lazy<T> {
  /// Creates the [Lazy] holding [value].
  const InitializedLazy(this.value);

  /// The value, known from the start.
  @override
  final T value;

  /// Always `true`: the value never needed computing.
  @override
  bool get isInitialized => true;

  /// Renders the value.
  @override
  String toString() => '$value';
}
