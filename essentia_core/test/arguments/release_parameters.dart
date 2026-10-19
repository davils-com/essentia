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

import 'package:essentia_core/src/arguments/parameter.dart';
import 'package:essentia_core/src/arguments/parameter_declarations.dart';
import 'package:essentia_core/src/arguments/parameters.dart';
import 'package:essentia_core/src/arguments/version_parameter_converters.dart';
import 'package:essentia_core/src/version/semantic_version.dart';
import 'package:essentia_core/src/version/semantic_version_range.dart';

/// A schema with a version and a version range, the parameters of a
/// release.
final class ReleaseParameters extends Parameters {
  /// The version released.
  final Parameter<SemanticVersion?> version = parameter(<String>['--version'])
      .semanticVersion();

  /// The versions of the host the release accepts.
  final Parameter<SemanticVersionRange?> accepts = parameter(<String>[
    '--accepts',
  ]).semanticVersionRange();

  /// Both parameters above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    version,
    accepts,
  ];
}
