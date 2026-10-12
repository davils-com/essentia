/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

/// A schema of parameters that split each occurrence on a comma.
final class SplitParameters extends Parameters {
  /// Creates the schema.
  SplitParameters();

  /// Text split on commas.
  final Parameter<List<String>> tags = parameter(<String>['--tag']).split(',');

  /// Integers split on commas.
  final Parameter<List<int>> ports = parameter(<String>['--port'])
      .integer()
      .split(',');

  /// A repeatable parameter split on a dot.
  final Parameter<List<String>> words = parameter(<String>['--word'])
      .multiple()
      .split('.');

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    tags,
    ports,
    words,
  ];
}
