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

/// A schema of two parameters whose names derive the same variable,
/// `APP_DATA_DIR`, unless one of them is opted out of the environment.
final class DerivedVariableParameters extends Parameters {
  /// Creates the schema, opting `--data_dir` out of the environment when
  /// [separated].
  DerivedVariableParameters({bool separated = false})
    : underscored = separated
          ? parameter(<String>['--data_dir']).integer().noEnv()
          : parameter(<String>['--data_dir']).integer(),
      super(environmentPrefix: 'APP');

  /// Derives `APP_DATA_DIR`.
  final Parameter<int?> dashed = parameter(<String>['--data-dir']).integer();

  /// Derives `APP_DATA_DIR` as well, unless it is separated.
  final Parameter<int?> underscored;

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    dashed,
    underscored,
  ];
}
