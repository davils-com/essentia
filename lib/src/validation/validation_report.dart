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
import 'package:essentia/src/validation/violation_renderer.dart';
import 'package:meta/meta.dart';

/// Everything one validation pass found.
///
/// A pass never stops at the first problem, so a report is the complete
/// answer: fix everything it lists and the next run succeeds. That is the
/// whole reason it exists as a value rather than as an exception thrown at
/// the first mistake.
@immutable
final class ValidationReport {
  /// Creates the report of a pass over [subject] that found [violations],
  /// rendered with [_footer] below them when one is given.
  @internal
  ValidationReport(this.subject, List<Violation> violations, {this._footer})
    : violations = List<Violation>.unmodifiable(violations);

  /// What was being validated, used in the headline: `"configuration"`,
  /// `"program parameters"`.
  final String subject;

  /// Everything found, errors and warnings together, in the order it was
  /// reported.
  final List<Violation> violations;

  /// The text rendered below the violations, or `null` for none.
  final String? _footer;

  /// The violations that make the result unusable.
  List<Violation> get errors => _withSeverity(Severity.error);

  /// The violations worth saying that do not stop anything.
  List<Violation> get warnings => _withSeverity(Severity.warning);

  /// Whether the result may be used.
  ///
  /// A report with warnings and no errors is valid; that is what separates
  /// the two severities.
  bool get isValid =>
      violations.every((violation) => violation.severity != Severity.error);

  /// Renders the report as the block of text a person reads.
  ///
  /// Errors come first, then warnings, each under its own headline and
  /// aligned into two columns.
  ///
  /// Returns the rendered report, without a trailing newline.
  String render() => renderReport(subject, violations, _footer);

  /// The rendered report.
  @override
  String toString() => render();

  /// Selects the violations that carry [severity].
  ///
  /// Returns them in the order they were reported.
  List<Violation> _withSeverity(Severity severity) =>
      List<Violation>.unmodifiable(
        violations.where((violation) => violation.severity == severity),
      );
}
