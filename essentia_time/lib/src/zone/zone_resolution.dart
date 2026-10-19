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

/// How a local time that a shift of the clocks makes ambiguous or skips
/// becomes a moment, when a time zone converts it to an `Instant`.
///
/// A local time in a gap, which the clocks jump over, is moved forward by
/// the length of the gap whatever is chosen, unless [strict]; a local time
/// in an overlap, which the clocks pass twice, takes the offset chosen.
enum ZoneResolution {
  /// The offset in effect before the shift: the first of two passes,
  /// RFC 5545's choice and the default.
  earlierOffset,

  /// The offset in effect after the shift: the second of two passes.
  laterOffset,

  /// Neither: a local time in a gap or an overlap is refused with a
  /// `DateTimeArithmeticException`.
  strict,
}
