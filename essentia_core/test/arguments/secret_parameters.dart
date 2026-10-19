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
