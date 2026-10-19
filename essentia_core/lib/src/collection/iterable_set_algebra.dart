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

import 'package:meta/meta.dart';

/// Set operations for any iterable, which treat the elements as a set and
/// keep the order they first appear in.
extension IterableSetAlgebra<T> on Iterable<T> {
  /// Keeps the distinct elements that [other] contains as well.
  ///
  /// Returns the shared elements as an unmodifiable set.
  @useResult
  Set<T> intersect(Iterable<T> other) =>
      Set<T>.unmodifiable(toSet()..retainAll(other));

  /// Joins the distinct elements of this iterable and of [other].
  ///
  /// Returns the joined elements as an unmodifiable set, those of this
  /// iterable first.
  @useResult
  Set<T> union(Iterable<T> other) =>
      Set<T>.unmodifiable(toSet()..addAll(other));

  /// Keeps the distinct elements that [other] does not contain.
  ///
  /// Returns the remaining elements as an unmodifiable set.
  @useResult
  Set<T> subtract(Iterable<T> other) =>
      Set<T>.unmodifiable(toSet()..removeAll(other));

  /// Checks whether every one of [elements] is among these elements.
  ///
  /// Returns `true` if none of [elements] is missing.
  @useResult
  bool containsAll(Iterable<T> elements) {
    final Set<T> own = toSet();
    return elements.every(own.contains);
  }
}
