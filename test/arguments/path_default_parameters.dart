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
