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

import 'package:essentia_core/essentia_core.dart';

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
