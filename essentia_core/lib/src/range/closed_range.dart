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

part 'comparable_closed_range.dart';

/// A range of comparable values from [start] up to and including
/// [endInclusive].
///
/// The range is empty when [start] lies beyond [endInclusive]. `IntRange`
/// is the closed range of integers that can also be iterated.
abstract interface class ClosedRange<T extends Comparable<Object>> {
  /// Creates the range from [start] up to and including [endInclusive].
  ///
  /// Two such ranges are equal when both of their ends are equal, and the
  /// range describes itself as `start..endInclusive`.
  const factory ClosedRange(T start, T endInclusive) = _ComparableClosedRange;

  /// The smallest value of the range.
  T get start;

  /// The largest value of the range, which the range contains.
  T get endInclusive;

  /// Whether the range holds no value, because [start] lies beyond
  /// [endInclusive].
  bool get isEmpty;

  /// Whether [value] lies between [start] and [endInclusive], both
  /// included.
  ///
  /// Returns `true` for a value of the range.
  bool contains(T value);
}
