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

/// A schema collecting unknown arguments, with repeatable parameters and a
/// deprecated flag.
final class TaggedParameters extends Parameters {
  /// Creates the schema.
  TaggedParameters() : super(unknownArguments: UnknownArgumentPolicy.collect);

  /// Repeatable text.
  final Parameter<List<String>> tags = parameter(<String>['--tag']).multiple();

  /// Repeatable integers with a default list.
  final Parameter<List<int>> ports = parameter(<String>['--port'])
      .integer()
      .multiple()
      .defaultsTo(<int>[80, 443]);

  /// A deprecated flag.
  final Parameter<bool> legacy = flag(<String>['--legacy']).deprecated();

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    tags,
    ports,
    legacy,
  ];
}
