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

import 'package:essentia_core/src/validation/reported_violation.dart';
import 'package:essentia_core/src/validation/severity.dart';
import 'package:essentia_core/src/validation/violation_code.dart';
import 'package:essentia_core/src/validation/violation_path.dart';

/// One thing that is wrong.
///
/// Everything Essentia validates reports through this one shape, which is
/// what lets a program argument and a nested configuration property end up
/// in the same report, rendered the same way, matched on the same way.
///
/// The four parts answer four different questions, and all four are
/// needed: [path] where, [code] what kind, [severity] how badly, [message]
/// what to do about it.
///
/// This is an interface rather than a class so that a caller with a richer
/// domain can keep its own types and still take part. `ParameterViolation`
/// is the example, and it stays a sealed hierarchy a caller can match on
/// exhaustively.
abstract interface class Violation {
  /// Creates a violation at [path] of the kind [code], saying [message],
  /// with [severity].
  ///
  /// The plain shape, for a caller that has nothing to add to it.
  ///
  /// ```dart
  /// final Violation missing = Violation.of(
  ///   ViolationPath.of('sinks').index(2).name('queueSize'),
  ///   ViolationCode.required,
  ///   'is required but was missing',
  /// );
  /// ```
  const factory Violation.of(
    ViolationPath path,
    ViolationCode code,
    String message, {
    Severity severity,
  }) = ReportedViolation.of;

  /// Where the problem is, as a path through the object being validated.
  ViolationPath get path;

  /// What kind of problem this is, as a stable identifier.
  ViolationCode get code;

  /// Whether this stops the result from being produced.
  Severity get severity;

  /// What is wrong, written for the person who has to fix it.
  ///
  /// It is rendered after the path, so it reads best as a continuation of
  /// it: `"must not be empty"` rather than `"The sinks list is empty"`.
  String get message;
}
