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
  /// Creates the schema reading [_firstVariable] for `--first` and
  /// [_secondVariable] for `--second`.
  NamedVariableParameters(this._firstVariable, this._secondVariable);

  /// The variable of `--first`.
  final String _firstVariable;

  /// The variable of `--second`.
  final String _secondVariable;

  /// Reads the first variable.
  late final Parameter<String?> first = parameter(<String>['--first'])
      .env(_firstVariable);

  /// Reads the second variable.
  late final Parameter<String?> second = parameter(<String>['--second'])
      .env(_secondVariable);

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[first, second];
}
