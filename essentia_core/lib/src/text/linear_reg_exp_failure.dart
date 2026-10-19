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

/// Why a pattern is refused by `LinearRegExp`.
enum LinearRegExpFailure {
  /// The pattern is no regular expression of ECMAScript in its unicode
  /// mode.
  syntax,

  /// The pattern uses what cannot be matched in linear time: a
  /// backreference, a lookahead or a lookbehind.
  unsupported,

  /// The pattern compiles to more instructions than allowed, as a large
  /// count of repetitions does.
  tooComplex,
}
