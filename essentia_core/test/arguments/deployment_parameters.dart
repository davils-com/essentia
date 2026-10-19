/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:essentia_core/essentia_core.dart';

/// The schema of a deployed service, deriving variables with the prefix
/// `APP`.
final class DeploymentParameters extends Parameters {
  /// Creates the schema.
  DeploymentParameters() : super(environmentPrefix: 'APP');

  /// The mode, production unless given.
  final Parameter<ApplicationMode> mode = parameter(<String>['--mode'])
      .applicationMode()
      .defaultsTo(ApplicationMode.production);

  /// The port, required and described.
  final Parameter<int> port = parameter(<String>['--port', '-p'])
      .integer()
      .required()
      .describedAs('The port to listen on.');

  /// A data directory that has to exist.
  final Parameter<String> dataDir = parameter(<String>['--data-dir'])
      .path(mustExist: true)
      .required();

  /// A required secret.
  final Parameter<String> dbPassword = parameter(<String>['--db-password'])
      .sensitive()
      .required();

  /// Repeatable tags.
  final Parameter<List<String>> tags = parameter(<String>['--tag']).multiple();

  /// A plain flag.
  final Parameter<bool> dryRun = flag(<String>['--dry-run']);

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
