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

/// A schema of parameters that split each occurrence on a comma.
final class SplitParameters extends Parameters {
  /// Creates the schema.
  SplitParameters();

  /// Text split on commas.
  final Parameter<List<String>> tags = parameter(<String>['--tag']).split(',');

  /// Integers split on commas.
  final Parameter<List<int>> ports = parameter(<String>['--port'])
      .integer()
      .split(',');

  /// A repeatable parameter split on a dot.
  final Parameter<List<String>> words = parameter(<String>['--word'])
      .multiple()
      .split('.');

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    tags,
    ports,
    words,
  ];
}
