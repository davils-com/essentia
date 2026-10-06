/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/validation/severity.dart';
import 'package:essentia/src/validation/violation.dart';
import 'package:essentia/src/validation/violation_code.dart';
import 'package:essentia/src/validation/violation_path.dart';
import 'package:meta/meta.dart';

/// The violation a validation scope records: the shared shape and nothing
/// more.
@internal
final class ReportedViolation implements Violation {
  /// Creates a violation at [path] with the given [code], [severity] and
  /// [message].
  const ReportedViolation(this.path, this.code, this.severity, this.message);

  /// Creates a violation at [path] of the kind [code], saying [message],
  /// with [severity], in the argument order of `Violation.of`.
  const ReportedViolation.of(
    this.path,
    this.code,
    this.message, {
    this.severity = Severity.error,
  });

  /// Where the problem is.
  @override
  final ViolationPath path;

  /// What kind of problem this is.
  @override
  final ViolationCode code;

  /// Whether this stops the result from being produced.
  @override
  final Severity severity;

  /// What is wrong.
  @override
  final String message;

  /// Renders the violation as its path followed by its message.
  @override
  String toString() => '$path $message';
}
