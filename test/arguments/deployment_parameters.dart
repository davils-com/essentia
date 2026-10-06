/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// The schema of a deployed service, deriving variables with the prefix
/// `APP`.
final class DeploymentParameters extends Parameters {
  /// Creates the schema.
  DeploymentParameters() : super(environmentPrefix: 'APP');

  /// The mode, production unless given.
  late final Parameter<ApplicationMode> mode = parameter(<String>['--mode'])
      .applicationMode()
      .defaultsTo(ApplicationMode.production);

  /// The port, required and described.
  late final Parameter<int> port = parameter(<String>['--port', '-p'])
      .integer()
      .required()
      .describedAs('The port to listen on.');

  /// A data directory that has to exist.
  late final Parameter<String> dataDir = parameter(<String>['--data-dir'])
      .path(mustExist: true)
      .required();

  /// A required secret.
  late final Parameter<String> dbPassword = parameter(<String>['--db-password'])
      .sensitive()
      .required();

  /// Repeatable tags.
  late final Parameter<List<String>> tags = parameter(<String>['--tag'])
      .multiple();

  /// A plain flag.
  late final Parameter<bool> dryRun = flag(<String>['--dry-run']);

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    mode,
    port,
    dataDir,
    dbPassword,
    tags,
    dryRun,
  ];
}
