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

/// A schema whose failures and values are reported, deriving variables with
/// the prefix `APP`.
final class ReportedParameters extends Parameters {
  /// Creates the schema.
  ReportedParameters() : super(environmentPrefix: 'APP');

  /// The mode, production unless given.
  final Parameter<ApplicationMode> mode = parameter(<String>['--mode'])
      .applicationMode()
      .defaultsTo(ApplicationMode.production);

  /// The port, required and described.
  final Parameter<int> port = parameter(<String>['--port', '-p'])
      .integer()
      .required()
      .describedAs('The port to listen on.');

  /// A required data directory.
  final Parameter<String> dataDir = parameter(<String>['--data-dir'])
      .required();

  /// An optional secret.
  final Parameter<String?> dbPassword = parameter(<String>['--db-password'])
      .sensitive();

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
