/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// A value computed on first use and kept from then on, Kotlin's `Lazy`.
///
/// Dart has no property delegates, so where Kotlin writes
/// `val word by lazy { Regex("^[a-z]+$") }` a field holds the [Lazy] itself and
/// reads [value] where the value is needed:
///
/// ```dart
/// final Lazy<RegExp> word = lazy(() => RegExp(r'^[a-z]+$'));
///
/// bool isWord(String text) => word.value.hasMatch(text);
/// ```
///
/// A [Lazy] is the way to defer a value without `late`: a field initialiser
/// cannot reach `this`, but it can hold a [Lazy] whose initializer runs
/// once the object exists.
abstract interface class Lazy<T> {
  /// The value, computed by the initializer on the first read.
  ///
  /// Every later read returns the same value without running the
  /// initializer again.
  T get value;

  /// Whether [value] has been computed, Kotlin's `isInitialized()`.
  ///
  /// Reading this never runs the initializer.
  bool get isInitialized;
}
