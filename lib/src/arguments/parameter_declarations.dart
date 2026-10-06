/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/arguments/boolean_parser.dart';
import 'package:essentia/src/arguments/flag_builder.dart';
import 'package:essentia/src/arguments/parameter_builder.dart';
import 'package:essentia/src/arguments/parameter_converters.dart';
import 'package:essentia/src/arguments/parameter_draft.dart';

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
