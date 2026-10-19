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

/// A schema with deprecated parameters, deriving variables with the prefix
/// `APP`.
final class AgeingParameters extends Parameters {
  /// Creates the schema.
  AgeingParameters() : super(environmentPrefix: 'APP');

  /// The parameter to use.
  final Parameter<String?> dataDir = parameter(<String>['--data-dir']);

  /// Deprecated in favour of [dataDir].
  final Parameter<String?> oldDir = parameter(<String>['--old-dir'])
      .deprecated('use --data-dir instead');

  /// Deprecated without advice.
  final Parameter<bool> legacy = flag(<String>['--legacy']).deprecated();

  /// Required.
  final Parameter<int> port = parameter(<String>['--port'])
      .integer()
      .required();

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    dataDir,
    oldDir,
    legacy,
    port,
  ];
}
