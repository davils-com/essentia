/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// A schema of two parameters reading the environment variables given to
/// its constructor.
final class NamedVariableParameters extends Parameters {
  /// Creates the schema reading [firstVariable] for `--first` and
  /// [secondVariable] for `--second`.
  NamedVariableParameters(String firstVariable, String secondVariable)
    : first = parameter(<String>['--first']).env(firstVariable),
      second = parameter(<String>['--second']).env(secondVariable);

  /// Reads the first variable.
  final Parameter<String?> first;

  /// Reads the second variable.
  final Parameter<String?> second;

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[first, second];
}
