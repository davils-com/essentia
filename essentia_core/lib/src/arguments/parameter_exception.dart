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
