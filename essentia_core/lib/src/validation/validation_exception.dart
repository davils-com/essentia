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
