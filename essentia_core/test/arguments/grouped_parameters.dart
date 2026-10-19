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

/// A schema with an exclusive pair and a dependency.
final class GroupedParameters extends Parameters {
  /// Creates the schema, making `--token` and `--key-file` exclusive and
  /// `--password` require `--user`.
  GroupedParameters() {
    exclusive(<Parameter<Object?>>[token, keyFile]);
    requires(password, <Parameter<Object?>>[user]);
  }

  /// Exclusive to [keyFile].
  final Parameter<String?> token = parameter(<String>['--token']);

  /// Exclusive to [token].
  final Parameter<String?> keyFile = parameter(<String>['--key-file']);

  /// Required by [password].
  final Parameter<String?> user = parameter(<String>['--user']);

  /// Requires [user].
  final Parameter<String?> password = parameter(<String>['--password']);

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    token,
    keyFile,
    user,
    password,
  ];
}
