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

import 'package:essentia_core/src/range/int_progression.dart';
import 'package:meta/meta.dart';

/// Builds integer ranges and progressions with [rangeTo], [until] and
/// [downTo].
extension IntRangeBuilding on int {
  /// The integers from this one up to and including [end].
  ///
  /// Returns the range, which is empty when [end] is smaller.
  @useResult
  IntRange rangeTo(int end) => IntRange(this, end);

  /// The integers from this one up to but excluding [end].
  ///
  /// Returns the range, which is empty when [end] is not larger.
  @useResult
  IntRange until(int end) => IntRange(this, end - 1);

  /// The integers from this one down to and including [end].
  ///
  /// Returns the progression with a step of minus one, which is empty when
  /// [end] is larger.
  @useResult
  IntProgression downTo(int end) => IntProgression(this, end, step: -1);
}
