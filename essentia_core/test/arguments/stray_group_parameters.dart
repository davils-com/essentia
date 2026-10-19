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

/// A schema whose group names a parameter missing from its declared list.
final class StrayGroupParameters extends Parameters {
  /// Creates the schema with `--quiet` exclusive to the undeclared
  /// `--timeout`.
  StrayGroupParameters.clashing() {
    exclusive(<Parameter<Object?>>[quiet, timeout]);
  }

  /// Creates the schema with `--user` requiring the undeclared
  /// `--password`.
  StrayGroupParameters.dependent() {
    requires(user, <Parameter<Object?>>[password]);
  }

  /// Declared.
  final Parameter<bool> quiet = flag(<String>['--quiet']);

  /// Not declared.
  final Parameter<bool> timeout = flag(<String>['--timeout']);

  /// Declared.
  final Parameter<String?> user = parameter(<String>['--user']);

  /// Not declared.
  final Parameter<String?> password = parameter(<String>['--password']);

  /// Declared and required, so that a resolving pass would fail.
  final Parameter<int> port = parameter(<String>['--port'])
      .integer()
      .required();

  /// The declared parameters, without `--timeout` and `--password`.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    quiet,
    user,
    port,
  ];
}
