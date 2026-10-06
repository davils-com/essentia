/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// A schema of sensitive parameters, deriving variables with the prefix
/// `APP`.
final class SecretParameters extends Parameters {
  /// Creates the schema.
  SecretParameters() : super(environmentPrefix: 'APP');

  /// A required secret.
  final Parameter<String> token = parameter(<String>['--token'])
      .sensitive()
      .required();

  /// Several secrets.
  final Parameter<List<String>> tags = parameter(<String>['--tag'])
      .sensitive()
      .multiple();

  /// A secret that is converted.
  final Parameter<int?> port = parameter(<String>['--port'])
      .integer()
      .sensitive();

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    token,
    tags,
    port,
  ];
}
