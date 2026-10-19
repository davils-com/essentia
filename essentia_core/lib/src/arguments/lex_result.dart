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
import 'package:essentia_core/src/arguments/raw_occurrence.dart';
import 'package:meta/meta.dart';

/// What reading the command line found, before anything was converted.
@internal
@immutable
final class LexResult {
  /// Creates the result.
  const LexResult(this.occurrences, this.unknown, this.rest, this.violations);

  /// The raw values by the ordinal of their parameter.
  final Map<int, List<RawOccurrence>> occurrences;

  /// The arguments that matched no parameter, when they are collected.
  final List<String> unknown;

  /// The arguments after the `--` terminator.
  final List<String> rest;

  /// What could not be read.
  final List<ParameterViolation> violations;
}
