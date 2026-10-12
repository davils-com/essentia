/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

/// A schema collecting unknown arguments, with repeatable parameters and a
/// deprecated flag.
final class TaggedParameters extends Parameters {
  /// Creates the schema.
  TaggedParameters() : super(unknownArguments: UnknownArgumentPolicy.collect);

  /// Repeatable text.
  final Parameter<List<String>> tags = parameter(<String>['--tag']).multiple();

  /// Repeatable integers with a default list.
  final Parameter<List<int>> ports = parameter(<String>['--port'])
      .integer()
      .multiple()
      .defaultsTo(<int>[80, 443]);

  /// A deprecated flag.
  final Parameter<bool> legacy = flag(<String>['--legacy']).deprecated();

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    tags,
    ports,
    legacy,
  ];
}
