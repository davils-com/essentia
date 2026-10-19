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

/// A value computed on first use and kept from then on.
///
/// A field holds the [Lazy] itself and reads [value] where the value is
/// needed:
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

  /// Whether [value] has been computed.
  ///
  /// Reading this never runs the initializer.
  bool get isInitialized;
}
