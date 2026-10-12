/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/validation/validation_report.dart';

/// Thrown when validation found something that makes the result unusable.
///
/// The exception carries the whole [report] rather than the first problem,
/// and its [message] is the rendered report. Printing the exception is
/// enough for a usable failure; [report] is there for callers that want to
/// react to particular violations by their code.
class ValidationException implements Exception {
  /// Creates the exception for [report].
  ///
  /// A library that reports through a [ValidationReport] of its own extends
  /// this class, so that a caller catching [ValidationException] catches
  /// its failures too.
  const ValidationException(this.report);

  /// Everything the pass found, including any warnings that accompanied the
  /// errors.
  final ValidationReport report;

  /// The rendered report.
  String get message => report.render();

  /// The rendered report.
  @override
  String toString() => message;
}
