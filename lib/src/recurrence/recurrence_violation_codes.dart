/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/validation/violation_code.dart';

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
