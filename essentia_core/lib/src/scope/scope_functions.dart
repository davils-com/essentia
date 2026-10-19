/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

/// Scope functions, for writing configuration blocks on any value.
///
/// A block takes the object it configures as its parameter, named `it` by
/// convention:
///
/// ```dart
/// final LoggingData config = LoggingBuilder().apply((it) {
///   it.level = LogLevel.debug;
/// }).build();
///
/// final int? port = environment['PORT']?.let(int.tryParse);
/// ```
extension ScopeFunctions<T> on T {
  /// Runs [block] on this value and returns the value itself.
  ///
  /// Returns this value.
  T apply(void Function(T it) block) {
    block(this);
    return this;
  }

  /// Runs [action] on this value and returns the value itself.
  ///
  /// The same as [apply]; the two names say whether the block configures
  /// the value or merely looks at it.
  ///
  /// Returns this value.
  T also(void Function(T it) action) {
    action(this);
    return this;
  }

  /// Runs [block] on this value and returns what the block returns.
  ///
  /// Returns the result of [block].
  R let<R>(R Function(T it) block) => block(this);

  /// Keeps this value when it satisfies [predicate].
  ///
  /// Returns this value, or `null` when [predicate] rejects it.
  T? takeIf(bool Function(T it) predicate) {
    if (predicate(this)) {
      return this;
    }
    return null;
  }

  /// Keeps this value unless it satisfies [predicate].
  ///
  /// Returns this value, or `null` when [predicate] accepts it.
  T? takeUnless(bool Function(T it) predicate) {
    if (predicate(this)) {
      return null;
    }
    return this;
  }
}
