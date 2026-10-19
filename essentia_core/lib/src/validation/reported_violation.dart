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

import 'package:essentia_core/src/validation/severity.dart';
import 'package:essentia_core/src/validation/violation.dart';
import 'package:essentia_core/src/validation/violation_code.dart';
import 'package:essentia_core/src/validation/violation_path.dart';
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
