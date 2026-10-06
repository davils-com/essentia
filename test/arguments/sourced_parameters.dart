/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// A schema of a secret and an integer that value sources supply.
final class SourcedParameters extends Parameters {
  /// Creates the schema.
  SourcedParameters();

  /// A secret.
  final Parameter<String?> token = parameter(<String>['--token']).sensitive();

  /// An integer.
  final Parameter<int?> region = parameter(<String>['--region']).integer();

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[token, region];
}
