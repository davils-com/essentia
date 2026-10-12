/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

/// A schema with an exclusive pair and a dependency.
final class GroupedParameters extends Parameters {
  /// Creates the schema, making `--token` and `--key-file` exclusive and
  /// `--password` require `--user`.
  GroupedParameters() {
    exclusive(<Parameter<Object?>>[token, keyFile]);
    requires(password, <Parameter<Object?>>[user]);
  }

  /// Exclusive to [keyFile].
  final Parameter<String?> token = parameter(<String>['--token']);

  /// Exclusive to [token].
  final Parameter<String?> keyFile = parameter(<String>['--key-file']);

  /// Required by [password].
  final Parameter<String?> user = parameter(<String>['--user']);

  /// Requires [user].
  final Parameter<String?> password = parameter(<String>['--password']);

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    token,
    keyFile,
    user,
    password,
  ];
}
