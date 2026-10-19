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

/// A schema whose converters throw something other than a
/// `ConversionException`.
final class CarelessParameters extends Parameters {
  /// Creates the schema.
  CarelessParameters();

  /// Converted by [int.parse], which throws a [FormatException].
  final Parameter<int?> port = parameter(<String>['--port'])
      .convert<int>('port', int.parse);

  /// Converted by the built-in integer conversion.
  final Parameter<int?> workers = parameter(<String>['--workers']).integer();

  /// A secret converted by [int.parse], whose exception quotes the value.
  final Parameter<int?> pin = parameter(<String>['--pin'])
      .sensitive()
      .convert<int>('pin', int.parse);

  /// Every parameter above.
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[
    port,
    workers,
    pin,
  ];
}
