/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/arguments.dart';

/// A schema deriving environment variables with the prefix `APP`.
final class EnvironmentParameters extends Parameters {
  /// Creates the schema.
  EnvironmentParameters() : super(environmentPrefix: 'APP');

  /// Falls back to `APP_DATA_DIR`.
  late final Parameter<String?> dataDir = parameter(<String>['--data-dir']);

  /// Falls back to `APP_PORT`, converted.
  late final Parameter<int?> port = parameter(<String>['--port', '-p'])
      .integer();

  /// Falls back to the explicitly named `VAULT_KEY`.
  late final Parameter<String?> secretKey = parameter(<String>['--secret-key'])
      .env('VAULT_KEY');

  /// Never falls back to the environment.
  late final Parameter<String?> local = parameter(<String>['--local']).noEnv();

  /// A flag falling back to `APP_EAGER`.
  late final Parameter<bool> eager = flag(<String>['--eager']);

  /// Falls back to `APP_TOKEN`.
  late final Parameter<String?> token = parameter(<String>['--token']);

  /// Falls back to `APP_REGION`.
  late final Parameter<String?> region = parameter(<String>['--region']);

  /// Falls back to `APP_ZONE`, then to its default.
  late final Parameter<String> zone = parameter(<String>['--zone'])
      .defaultsTo('local');

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    dataDir,
    port,
    secretKey,
    local,
    eager,
    token,
    region,
    zone,
  ];
}
