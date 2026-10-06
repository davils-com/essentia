/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/arguments.dart';

/// A schema whose assignments are spelt in every legal way, deriving
/// variables with the prefix `APP`.
final class SpellingParameters extends Parameters {
  /// Creates the schema.
  SpellingParameters() : super(environmentPrefix: 'APP');

  /// Required text, with a short name.
  late final Parameter<String> host = parameter(<String>['--host', '-h'])
      .required();

  /// A required integer, with a short name.
  late final Parameter<int> port = parameter(<String>['--port', '-p'])
      .integer()
      .required();

  /// A flag, with a short name.
  late final Parameter<bool> verbose = flag(<String>['--verbose', '-v']);

  /// Another flag, with a short name.
  late final Parameter<bool> archive = flag(<String>['--archive', '-a']);

  /// A negatable flag.
  late final Parameter<bool> colour = flag(<String>['--colour']).negatable();

  /// A repeatable parameter, with a short name.
  late final Parameter<List<String>> tags = parameter(<String>['--tag', '-t'])
      .multiple();

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    host,
    port,
    verbose,
    archive,
    colour,
    tags,
  ];
}
