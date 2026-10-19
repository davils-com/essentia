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

import 'package:essentia_core/src/arguments/cardinality.dart';
import 'package:essentia_core/src/arguments/parameter_info.dart';
import 'package:essentia_core/src/validation/validation_scope.dart';
import 'package:meta/meta.dart';

/// A registered parameter: its description, its position in the schema and
/// everything resolving it needs.
@internal
@immutable
final class ParameterSpec {
  /// Creates the spec of the parameter at [ordinal].
  const ParameterSpec({
    required this.info,
    required this.ordinal,
    required this.cardinality,
    required this.converter,
    required this.constraint,
    required this.validators,
    required this.defaultValue,
    required this.splitDelimiter,
    required this.isNegatable,
    required this.collect,
  });

  /// The prefix of a long name.
  static const longPrefix = '--';

  /// What a negated long name inserts after the prefix.
  static const negationInfix = 'no-';

  /// The public description.
  final ParameterInfo info;

  /// The position in the schema, which is also the slot of the value.
  final int ordinal;

  /// How many values the parameter resolves to.
  final Cardinality cardinality;

  /// Turns raw text into the declared type.
  final Object? Function(String raw) converter;

  /// The check the conversion installed, run on a converted value and on a
  /// declared default alike, or `null`.
  final void Function(Object? value)? constraint;

  /// The rules a converted value has to satisfy.
  final List<void Function(ValidationScope scope, Object? value)> validators;

  /// The value used when no source supplies one.
  final Object? defaultValue;

  /// What one occurrence is split on, or `null`.
  final String? splitDelimiter;

  /// Whether the flag answers to its `--no-` names.
  final bool isNegatable;

  /// Collects the values of a parameter that takes several into the list
  /// its readers expect.
  final List<Object?> Function(List<Object?> values) collect;

  /// Every name the parameter answers to, negated ones included.
  ///
  /// Returns the names.
  List<String> matchableNames() => <String>[...info.names, ...negatedNames()];

  /// The `--no-` names of a negatable flag.
  ///
  /// Returns one negated name per long name, or nothing.
  List<String> negatedNames() {
    if (!isNegatable) {
      return const <String>[];
    }
    return <String>[
      for (final String name in info.names)
        if (name.startsWith(longPrefix))
          '$longPrefix$negationInfix${name.substring(longPrefix.length)}',
    ];
  }
}
