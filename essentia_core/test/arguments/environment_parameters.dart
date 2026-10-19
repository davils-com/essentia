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

/// A schema deriving environment variables with the prefix `APP`.
final class EnvironmentParameters extends Parameters {
  /// Creates the schema.
  EnvironmentParameters() : super(environmentPrefix: 'APP');

  /// Falls back to `APP_DATA_DIR`.
  final Parameter<String?> dataDir = parameter(<String>['--data-dir']);

  /// Falls back to `APP_PORT`, converted.
  final Parameter<int?> port = parameter(<String>['--port', '-p']).integer();

  /// Falls back to the explicitly named `VAULT_KEY`.
  final Parameter<String?> secretKey = parameter(<String>['--secret-key'])
      .env('VAULT_KEY');

  /// Never falls back to the environment.
  final Parameter<String?> local = parameter(<String>['--local']).noEnv();

  /// A flag falling back to `APP_EAGER`.
  final Parameter<bool> eager = flag(<String>['--eager']);

  /// Falls back to `APP_TOKEN`.
  final Parameter<String?> token = parameter(<String>['--token']);

  /// Falls back to `APP_REGION`.
  final Parameter<String?> region = parameter(<String>['--region']);

  /// Falls back to `APP_ZONE`, then to its default.
  final Parameter<String> zone = parameter(<String>['--zone'])
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
