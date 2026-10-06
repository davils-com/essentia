/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/validation/violation_code.dart';

/// The stable identifiers of what can be wrong with a written version or
/// range.
///
/// A message may be reworded at any time; these do not change.
abstract final class VersionViolationCodes {
  /// A text meant to be a semantic version is not one.
  static const invalidVersion = ViolationCode(
    'essentia.version.invalid-version',
  );

  /// A text meant to be a version range is not one, or describes a range
  /// with nothing in it.
  static const invalidRange = ViolationCode('essentia.version.invalid-range');
}
