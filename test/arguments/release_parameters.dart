/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/arguments/parameter.dart';
import 'package:essentia/src/arguments/parameters.dart';
import 'package:essentia/src/arguments/version_parameter_converters.dart';
import 'package:essentia/src/version/semantic_version.dart';
import 'package:essentia/src/version/semantic_version_range.dart';

/// A schema with a version and a version range, the parameters of a
/// release.
final class ReleaseParameters extends Parameters {
  /// The version released.
  late final Parameter<SemanticVersion?> version = parameter(<String>[
    '--version',
  ]).semanticVersion();

  /// The versions of the host the release accepts.
  late final Parameter<SemanticVersionRange?> accepts = parameter(<String>[
    '--accepts',
  ]).semanticVersionRange();

  /// Both parameters above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    version,
    accepts,
  ];
}
