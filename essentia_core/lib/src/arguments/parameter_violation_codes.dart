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

import 'package:essentia_core/src/validation/violation_code.dart';

/// The stable identifiers of everything that can go wrong with a program's
/// parameters.
///
/// A message may be reworded at any time; these do not change. Match on
/// them to react to a particular kind of problem, or to key a translation
/// by.
abstract final class ParameterViolationCodes {
  /// A required parameter had no value in any source.
  static const missingRequired = ViolationCode(
    'essentia.parameter.missing-required',
  );

  /// A parameter that takes a value had nothing following it.
  static const missingValue = ViolationCode('essentia.parameter.missing-value');

  /// An argument matched no declared parameter.
  static const unknownArgument = ViolationCode(
    'essentia.parameter.unknown-argument',
  );

  /// An argument could not be read as a parameter at all.
  static const malformedArgument = ViolationCode(
    'essentia.parameter.malformed-argument',
  );

  /// A value appeared where a parameter was expected.
  static const strayValue = ViolationCode('essentia.parameter.stray-value');

  /// A converter rejected the value it was given.
  static const conversionFailed = ViolationCode(
    'essentia.parameter.conversion-failed',
  );

  /// A value converted cleanly but failed a rule declared for it.
  static const validationFailed = ViolationCode(
    'essentia.parameter.validation-failed',
  );

  /// A single-valued parameter was given more than once.
  static const repeated = ViolationCode('essentia.parameter.repeated');

  /// Parameters declared as mutually exclusive were given together.
  static const mutuallyExclusive = ViolationCode(
    'essentia.parameter.mutually-exclusive',
  );

  /// A parameter was given without one it depends on.
  static const missingDependency = ViolationCode(
    'essentia.parameter.missing-dependency',
  );

  /// A parameter that is still honoured but should no longer be used was
  /// given.
  ///
  /// This is the one code that is a warning: loading succeeds and the value
  /// is used.
  static const deprecated = ViolationCode('essentia.parameter.deprecated');

  /// A value source failed while being asked for a value.
  ///
  /// Distinct from every other code here because it is not a problem with
  /// what anybody passed: the arguments may be fine and the secret store
  /// down. A program that matches on it can retry, or exit with a different
  /// status than it would for a bad argument.
  static const sourceUnavailable = ViolationCode(
    'essentia.parameter.source-unavailable',
  );
}
