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

import 'package:essentia_core/src/range/closed_range.dart';
import 'package:meta/meta.dart';

/// Keeps a comparable value within bounds.
extension ComparableCoercion<T extends Comparable<Object>> on T {
  /// Raises this value to [minimum] when it lies below it.
  ///
  /// Returns this value, or [minimum] when this value is smaller.
  @useResult
  T coerceAtLeast(T minimum) => compareTo(minimum) < 0 ? minimum : this;

  /// Lowers this value to [maximum] when it lies above it.
  ///
  /// Returns this value, or [maximum] when this value is larger.
  @useResult
  T coerceAtMost(T maximum) => compareTo(maximum) > 0 ? maximum : this;

  /// Moves this value into the bounds [minimum] and [maximum], both
  /// included.
  ///
  /// Returns this value, or the bound it lies beyond.
  ///
  /// Throws an [ArgumentError] if [minimum] exceeds [maximum].
  @useResult
  T coerceIn(T minimum, T maximum) {
    if (minimum.compareTo(maximum) > 0) {
      throw ArgumentError(
        'The range $minimum..$maximum is empty, $minimum exceeds $maximum.',
      );
    }
    return coerceAtLeast(minimum).coerceAtMost(maximum);
  }

  /// Moves this value into [range].
  ///
  /// Returns this value, or the end of [range] it lies beyond.
  ///
  /// Throws an [ArgumentError] if [range] is empty.
  @useResult
  T coerceInRange(ClosedRange<T> range) {
    if (range.isEmpty) {
      throw ArgumentError.value(range, 'range', 'must not be empty');
    }
    return coerceIn(range.start, range.endInclusive);
  }
}
