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

import 'package:essentia_core/src/arguments/boolean_parser.dart';
import 'package:essentia_core/src/arguments/flag_builder.dart';
import 'package:essentia_core/src/arguments/parameter_builder.dart';
import 'package:essentia_core/src/arguments/parameter_converters.dart';
import 'package:essentia_core/src/arguments/parameter_draft.dart';

/// Declares a parameter answering to [names], each starting with `--`
/// or being a single character after one `-`.
///
/// A schema initialises a final field with it and lists that field in its
/// declared parameters, which is what ties the parameter to the schema.
///
/// Returns a builder reading the value as text; a conversion such as
/// [ParameterConverters.integer] changes its type.
///
/// Throws an [ArgumentError] if a name is malformed.
ParameterBuilder<String> parameter(List<String> names) {
  _validateNames(names);
  return ParameterBuilder<String>(
    ParameterDraft(
      names: List<String>.unmodifiable(names),
      converter: (raw) => raw,
      typeName: 'string',
      isFlag: false,
    ),
  );
}

/// Declares a flag answering to [names].
///
/// Returns a builder reading `true` when the flag is given.
///
/// Throws an [ArgumentError] if a name is malformed.
FlagBuilder flag(List<String> names) {
  _validateNames(names);
  return FlagBuilder(
    ParameterDraft(
      names: List<String>.unmodifiable(names),
      converter: parseBoolean,
      typeName: 'flag',
      isFlag: true,
    ),
  );
}

/// Checks the declared [names] of one parameter.
///
/// Throws an [ArgumentError] if there are none, or one does not start
/// with a dash, has nothing after its dashes, or is a short name longer
/// than one character.
void _validateNames(List<String> names) {
  if (names.isEmpty) {
    throw ArgumentError('A parameter needs at least one name');
  }
  for (final name in names) {
    if (!name.startsWith('-')) {
      throw ArgumentError('Parameter name "$name" must start with a dash');
    }
    if (name.startsWith('--')) {
      if (name.length <= 2) {
        throw ArgumentError(
          'Parameter name "$name" has no name after its dashes',
        );
      }
      continue;
    }
    if (name.length != 2) {
      throw ArgumentError(
        'Short parameter name "$name" must be exactly one character, or '
        'start with "--"',
      );
    }
  }
}
