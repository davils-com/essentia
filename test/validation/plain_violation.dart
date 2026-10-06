/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:meta/meta.dart';

/// A violation written by hand, for the report rendering tests.
@immutable
final class PlainViolation implements Violation {
  /// Creates an error at [path] saying [message].
  PlainViolation.error(String path, this.message)
    : path = _pathOf(path),
      severity = Severity.error,
      code = ViolationCode.invalid;

  /// Creates a warning at [path] saying [message].
  PlainViolation.warning(String path, this.message)
    : path = _pathOf(path),
      severity = Severity.warning,
      code = ViolationCode.invalid;

  /// Where the problem is.
  @override
  final ViolationPath path;

  /// What kind of problem this is.
  @override
  final ViolationCode code;

  /// How badly it matters.
  @override
  final Severity severity;

  /// What is wrong.
  @override
  final String message;

  /// The path named [value], or the root path when [value] is empty.
  static ViolationPath _pathOf(String value) =>
      value.isEmpty ? ViolationPath.root : ViolationPath.of(value);
}
