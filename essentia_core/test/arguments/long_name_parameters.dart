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

/// A schema with one parameter whose name is wider than every column.
final class LongNameParameters extends Parameters {
  /// Creates the schema.
  LongNameParameters();

  /// A required parameter with a name of 37 characters.
  final Parameter<int> long = parameter(<String>[
    '--a-parameter-with-a-really-long-name',
  ]).integer().required();

  /// A required parameter with a short name.
  final Parameter<int> short = parameter(<String>['--b']).integer().required();

  /// Every parameter, in the order of the usage listing.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[long, short];
}
