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

import 'package:essentia_core/essentia_core.dart';

/// The stable identifiers of what can be wrong with a `RecurrenceRule`.
///
/// A message may be reworded at any time; these do not change.
abstract final class RecurrenceViolationCodes {
  /// The interval is not positive.
  static const interval = ViolationCode('essentia.recurrence.interval');

  /// The count is not positive.
  static const count = ViolationCode('essentia.recurrence.count');

  /// Both a count and an end were given.
  static const countAndUntil = ViolationCode(
    'essentia.recurrence.count-and-until',
  );

  /// A value of a `BY` part lies outside its range.
  static const outOfRange = ViolationCode('essentia.recurrence.out-of-range');

  /// A `BY` part does not apply to the frequency.
  static const notApplicable = ViolationCode(
    'essentia.recurrence.not-applicable',
  );

  /// A weekday carries an ordinal where none is allowed.
  static const ordinal = ViolationCode('essentia.recurrence.ordinal');

  /// `BYSETPOS` stands without another `BY` part to select from.
  static const setPositionAlone = ViolationCode(
    'essentia.recurrence.set-position-alone',
  );
}
