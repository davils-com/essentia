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

import 'dart:io';

import 'package:essentia_core/essentia_core.dart';

/// A schema of checked paths that fall back to defaults given to its
/// constructor.
final class PathDefaultParameters extends Parameters {
  /// Creates the schema falling back to [dataDirDefault] for `--data-dir`
  /// and to [configDefault] for `--config`.
  PathDefaultParameters(String dataDirDefault, String configDefault)
    : dataDir = parameter(<String>['--data-dir'])
          .path(mustExist: true, mustBeDirectory: true)
          .defaultsTo(dataDirDefault),
      config = parameter(<String>['--config'])
          .file(mustExist: true)
          .defaultsTo(File(configDefault));

  /// A directory that has to exist.
  final Parameter<String> dataDir;

  /// A file that has to exist.
  final Parameter<File> config;

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    dataDir,
    config,
  ];
}
