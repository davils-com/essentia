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

/// How a number that falls between two representable values is rounded.
enum RoundingMode {
  /// Towards positive infinity: 1.1 is 2, -1.9 is -1.
  ceiling,

  /// Towards negative infinity: 1.9 is 1, -1.1 is -2.
  floor,

  /// Towards zero, cutting the digits off: 1.9 is 1, -1.9 is -1.
  down,

  /// Away from zero: 1.1 is 2, -1.1 is -2.
  up,

  /// To the nearest neighbour, a tie to the even one: 2.5 is 2, 3.5 is 4.
  /// What CLDR formats with unless told otherwise.
  halfEven,

  /// To the nearest neighbour, a tie away from zero: 2.5 is 3, -2.5 is -3.
  halfUp,

  /// To the nearest neighbour, a tie towards zero: 2.5 is 2, -2.5 is -2.
  halfDown,
}
