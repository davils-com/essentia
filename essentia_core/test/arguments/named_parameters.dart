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

/// A schema declaring two parameters under names given from outside, and
/// one parameter it forgets to list.
final class NamedParameters extends Parameters {
  /// Creates the schema declaring [firstNames] and [secondNames].
  NamedParameters(List<String> firstNames, List<String> secondNames)
    : first = parameter(firstNames),
      second = parameter(secondNames);

  /// Answers to the first names.
  final Parameter<String?> first;

  /// Answers to the second names.
  final Parameter<String?> second;

  /// Created on the schema but missing from [declared].
  final Parameter<String?> orphan = parameter(<String>['--orphan']);

  /// [first] and [second], but not [orphan].
  @override
  List<Parameter<Object?>> get declared => <Parameter<Object?>>[first, second];
}
