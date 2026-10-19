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

/// A schema whose paths are checked against the file system.
final class PathParameters extends Parameters {
  /// A directory that has to exist.
  final Parameter<String?> directory = parameter(<String>['--dir'])
      .path(mustExist: true, mustBeDirectory: true);

  /// A regular file.
  final Parameter<File?> file = parameter(<String>['--file'])
      .file(mustBeRegularFile: true);

  /// Anything that can be read.
  final Parameter<String?> readable = parameter(<String>['--readable'])
      .path(mustBeReadable: true);

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    directory,
    file,
    readable,
  ];
}
