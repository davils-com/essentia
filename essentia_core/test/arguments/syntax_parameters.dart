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

/// A schema exercising every way a command line can spell a parameter.
final class SyntaxParameters extends Parameters {
  /// Text, with a short name.
  final Parameter<String?> name = parameter(<String>['--name', '-n']);

  /// An integer, with a short name.
  final Parameter<int?> port = parameter(<String>['--port', '-p']).integer();

  /// A flag, with a short name.
  final Parameter<bool> verbose = flag(<String>['--verbose', '-v']);

  /// Another flag, with a short name.
  final Parameter<bool> archive = flag(<String>['--archive', '-a']);

  /// A negatable flag that is on unless turned off.
  final Parameter<bool> colour = flag(<String>['--colour'])
      .negatable()
      .enabledByDefault();

  /// A repeatable parameter, with a short name.
  final Parameter<List<String>> tags = parameter(<String>['--tag', '-t'])
      .multiple();

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    name,
    port,
    verbose,
    archive,
    colour,
    tags,
  ];
}
