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
import 'package:essentia_core/src/range/open_end_range.dart';
import 'package:meta/meta.dart';

/// Builds closed and open-ended ranges of comparable values.
///
/// For integers, `IntRangeBuilding` is the more specific extension and
/// builds an iterable `IntRange` instead.
extension ComparableRangeBuilding<T extends Comparable<Object>> on T {
  /// The values from this one up to and including [end].
  ///
  /// Returns the range, which is empty when [end] is smaller.
  @useResult
  ClosedRange<T> rangeTo(T end) => ClosedRange<T>(this, end);

  /// The values from this one up to but excluding [end].
  ///
  /// Returns the range, which is empty when [end] is not larger.
  @useResult
  OpenEndRange<T> rangeUntil(T end) => OpenEndRange<T>(this, end);
}
