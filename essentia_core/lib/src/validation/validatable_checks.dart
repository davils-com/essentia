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

import 'package:essentia_core/src/validation/validatable.dart';
import 'package:essentia_core/src/validation/validation_exception.dart';
import 'package:essentia_core/src/validation/validation_report.dart';
import 'package:essentia_core/src/validation/validation_scope.dart';
import 'package:essentia_core/src/validation/violation_code.dart';
import 'package:essentia_core/src/validation/violation_path.dart';

/// Validates a value that no builder assembled.
///
/// A configuration object reaches its invariants through
/// `ValidatingBuilder.validate`, because a builder is what put it together.
/// A value that arrived from outside the program has no builder: it was
/// decoded from a request body, read out of a row, or handed over by a
/// caller. These are the same pass for that case.
///
/// ```dart
/// final ValidationReport report = dto.validateAs('workspace');
/// if (!report.isValid) {
///   return badRequest(report.render());
/// }
/// final Workspace workspace = dto.validateOrThrow('workspace').toDomain();
/// ```
extension ValidatableChecks<T extends Validatable> on T {
  /// Validates this value, returning everything that is wrong with it.
  ///
  /// Like every pass in Essentia, this one runs every rule rather than
  /// stopping at the first failure. [subject] names what is validated in
  /// the headline: `"workspace"` renders as
  /// `Invalid workspace (2 problems):`.
  ///
  /// Returns the report, valid or not.
  ValidationReport validateAs(String subject) {
    final scope = ValidationScope(ViolationPath.root, ViolationCode.invalid);
    validate(scope);
    return ValidationReport(subject, scope.violations());
  }

  /// Validates this value and throws unless it is usable.
  ///
  /// The value is returned so that the check reads as one step of the
  /// boundary it guards. Warnings do not stop anything; use [validateAs]
  /// where they have to be read as well.
  ///
  /// Returns this value, unchanged.
  ///
  /// Throws a [ValidationException] carrying every problem found if
  /// anything makes the value unusable.
  T validateOrThrow(String subject) {
    final ValidationReport report = validateAs(subject);
    if (!report.isValid) {
      throw ValidationException(report);
    }
    return this;
  }
}
