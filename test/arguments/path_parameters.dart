/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:io';

import 'package:essentia/essentia.dart';

/// A schema whose paths are checked against the file system.
final class PathParameters extends Parameters {
  /// A directory that has to exist.
  late final Parameter<String?> directory = parameter(<String>['--dir'])
      .path(mustExist: true, mustBeDirectory: true);

  /// A regular file.
  late final Parameter<File?> file = parameter(<String>['--file'])
      .file(mustBeRegularFile: true);

  /// Anything that can be read.
  late final Parameter<String?> readable = parameter(<String>['--readable'])
      .path(mustBeReadable: true);

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    directory,
    file,
    readable,
  ];
}
