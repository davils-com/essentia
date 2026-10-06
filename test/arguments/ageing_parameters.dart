/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/arguments.dart';

/// A schema with deprecated parameters, deriving variables with the prefix
/// `APP`.
final class AgeingParameters extends Parameters {
  /// Creates the schema.
  AgeingParameters() : super(environmentPrefix: 'APP');

  /// The parameter to use.
  late final Parameter<String?> dataDir = parameter(<String>['--data-dir']);

  /// Deprecated in favour of [dataDir].
  late final Parameter<String?> oldDir = parameter(<String>['--old-dir'])
      .deprecated('use --data-dir instead');

  /// Deprecated without advice.
  late final Parameter<bool> legacy = flag(<String>['--legacy']).deprecated();

  /// Required.
  late final Parameter<int> port = parameter(<String>['--port'])
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
