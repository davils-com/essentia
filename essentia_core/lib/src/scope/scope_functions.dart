/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
