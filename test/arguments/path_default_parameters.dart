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
  /// Creates the schema falling back to [_dataDir] for `--data-dir` and to
  /// [_config] for `--config`.
  PathDefaultParameters(this._dataDir, this._config);

  /// The default of `--data-dir`.
  final String _dataDir;

  /// The default of `--config`.
  final String _config;

  /// A directory that has to exist.
  late final Parameter<String> dataDir = parameter(<String>['--data-dir'])
      .path(mustExist: true, mustBeDirectory: true)
      .defaultsTo(_dataDir);

  /// A file that has to exist.
  late final Parameter<File> config = parameter(<String>['--config'])
      .file(mustExist: true)
      .defaultsTo(File(_config));

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    dataDir,
    config,
  ];
}
