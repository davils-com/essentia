/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// A schema of two parameters whose names derive the same variable,
/// `APP_DATA_DIR`, unless one of them is opted out of the environment.
final class DerivedVariableParameters extends Parameters {
  /// Creates the schema, opting `--data_dir` out of the environment when
  /// [_separated].
  DerivedVariableParameters({this._separated = false})
    : super(environmentPrefix: 'APP');

  /// Whether `--data_dir` is opted out of the environment.
  final bool _separated;

  /// Derives `APP_DATA_DIR`.
  late final Parameter<int?> dashed = parameter(<String>['--data-dir'])
      .integer();

  /// Derives `APP_DATA_DIR` as well, unless it is separated.
  late final Parameter<int?> underscored = _separated
      ? parameter(<String>['--data_dir']).integer().noEnv()
      : parameter(<String>['--data_dir']).integer();

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    dashed,
    underscored,
  ];
}
