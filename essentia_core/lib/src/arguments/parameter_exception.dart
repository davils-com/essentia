/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/arguments/parameter_violation.dart';
import 'package:essentia_core/src/validation/validation_exception.dart';
import 'package:essentia_core/src/validation/validation_report.dart';
import 'package:meta/meta.dart';

/// Thrown when the parameters a program was started with cannot be
/// resolved.
///
/// The exception carries every problem found in a single pass rather than
/// only the first one, and its message renders them together with the
/// listing of supported parameters. Printing the exception is enough for a
/// usable startup failure; [violations] is there for callers that want to
/// react to specific kinds of problems, and [report] for those that would
/// rather work against the shared shape.
final class ParameterException extends ValidationException {
  /// Creates the exception for [violations], followed by [usage].
  @internal
  ParameterException(List<ParameterViolation> violations, this.usage)
    : violations = List<ParameterViolation>.unmodifiable(violations),
      super(ValidationReport('program parameters', violations, footer: usage));

  /// Every problem found, in the order the parameters were declared.
  final List<ParameterViolation> violations;

  /// The rendered listing of supported parameters.
  final String usage;
}
