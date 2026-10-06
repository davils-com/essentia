/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// A schema exercising every way a command line can spell a parameter.
final class SyntaxParameters extends Parameters {
  /// Text, with a short name.
  final Parameter<String?> name = parameter(<String>['--name', '-n']);

  /// An integer, with a short name.
  final Parameter<int?> port = parameter(<String>['--port', '-p']).integer();

  /// A flag, with a short name.
  final Parameter<bool> verbose = flag(<String>['--verbose', '-v']);

  /// Another flag, with a short name.
  final Parameter<bool> archive = flag(<String>['--archive', '-a']);

  /// A negatable flag that is on unless turned off.
  final Parameter<bool> colour = flag(<String>['--colour'])
      .negatable()
      .enabledByDefault();

  /// A repeatable parameter, with a short name.
  final Parameter<List<String>> tags = parameter(<String>['--tag', '-t'])
      .multiple();

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    name,
    port,
    verbose,
    archive,
    colour,
    tags,
  ];
}
