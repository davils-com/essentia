/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

/// A schema with a required parameter and a defaulted one.
final class MandatoryParameters extends Parameters {
  /// Creates the schema, deriving variables with [environmentPrefix] when
  /// one is given.
  MandatoryParameters({super.environmentPrefix});

  /// Required.
  final Parameter<int> port = parameter(<String>['--port'])
      .integer()
      .required();

  /// Defaults to `localhost`.
  final Parameter<String> host = parameter(<String>['--host'])
      .defaultsTo('localhost');

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[port, host];
}
