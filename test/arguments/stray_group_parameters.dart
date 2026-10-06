/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// A schema whose group names a parameter missing from its declared list.
final class StrayGroupParameters extends Parameters {
  /// Creates the schema with `--quiet` exclusive to the undeclared
  /// `--timeout`.
  StrayGroupParameters.clashing() {
    exclusive(<Parameter<Object?>>[quiet, timeout]);
  }

  /// Creates the schema with `--user` requiring the undeclared
  /// `--password`.
  StrayGroupParameters.dependent() {
    requires(user, <Parameter<Object?>>[password]);
  }

  /// Declared.
  final Parameter<bool> quiet = flag(<String>['--quiet']);

  /// Not declared.
  final Parameter<bool> timeout = flag(<String>['--timeout']);

  /// Declared.
  final Parameter<String?> user = parameter(<String>['--user']);

  /// Not declared.
  final Parameter<String?> password = parameter(<String>['--password']);

  /// Declared and required, so that a resolving pass would fail.
  final Parameter<int> port = parameter(<String>['--port'])
      .integer()
      .required();

  /// The declared parameters, without `--timeout` and `--password`.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    quiet,
    user,
    port,
  ];
}
