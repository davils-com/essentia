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

part 'comparable_open_end_range.dart';

/// A range of comparable values from [start] up to but excluding
/// [endExclusive].
///
/// The range is empty when [start] reaches [endExclusive].
abstract interface class OpenEndRange<T extends Comparable<Object>> {
  /// Creates the range from [start] up to but excluding [endExclusive].
  ///
  /// Two such ranges are equal when both of their ends are equal, and the
  /// range describes itself as `start..<endExclusive`.
  const factory OpenEndRange(T start, T endExclusive) = _ComparableOpenEndRange;

  /// The smallest value of the range.
  T get start;

  /// The first value beyond the range, which the range does not contain.
  T get endExclusive;

  /// Whether the range holds no value, because [start] reaches
  /// [endExclusive].
  bool get isEmpty;

  /// Whether [value] lies between [start], included, and [endExclusive],
  /// excluded.
  ///
  /// Returns `true` for a value of the range.
  bool contains(T value);
}
