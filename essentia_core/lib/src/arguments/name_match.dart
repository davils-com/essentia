/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/arguments/parameter_spec.dart';
import 'package:meta/meta.dart';

/// The parameter a name on the command line belongs to.
@internal
@immutable
final class NameMatch {
  /// Creates the match of [spec], negated or not.
  const NameMatch(this.spec, {required this.negated});

  /// The parameter.
  final ParameterSpec spec;

  /// Whether the name was the `--no-` form of a flag.
  final bool negated;
}
