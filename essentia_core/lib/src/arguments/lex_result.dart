/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
