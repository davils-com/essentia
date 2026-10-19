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
import 'package:essentia_core/src/arguments/parameter.dart';
import 'package:essentia_core/src/arguments/parameter_draft.dart';
import 'package:essentia_core/src/arguments/parameters.dart';
import 'package:meta/meta.dart';

/// What every builder of a parameter is: a declaration that one schema
/// lists, and the handle its value of type [V] is read through.
@internal
abstract class DeclaredParameter<V> implements Parameter<V> {
  /// Creates the declaration [draft], which no schema lists yet.
  DeclaredParameter(this.draft);

  /// The schema listing the parameter, once one registered it.
  Parameters? _schema;

  /// The schema listing the parameter, or `null` while none registered it.
  Parameters? get schema => _schema;

  /// The declaration so far.
  final ParameterDraft draft;

  /// How many values the parameter resolves to.
  Cardinality get cardinality;

  /// The value used when no source supplies one, or `null`.
  Object? get defaultValue;

  /// Collects the resolved [values] of a parameter that takes several into
  /// the list its readers expect.
  ///
  /// Returns an unmodifiable list, typed by the parameter.
  List<Object?> collect(List<Object?> values) =>
      List<Object?>.unmodifiable(values);

  /// Records that [owner] lists the parameter in its declared parameters.
  ///
  /// Throws an [ArgumentError] if another schema lists it already; a
  /// parameter belongs to exactly one schema.
  void declareOn(Parameters owner) {
    final Parameters? current = _schema;
    if (current != null && !identical(current, owner)) {
      throw ArgumentError(
        'Parameter "${draft.names.first}" is declared by another schema. '
        'A parameter belongs to one schema; declare it on each schema.',
      );
    }
    _schema = owner;
  }

  /// The resolved value, read from the snapshot of the schema listing it.
  ///
  /// Throws a `ParametersNotLoadedError` if that schema was not loaded
  /// yet, and a [StateError] if no schema lists the parameter.
  @override
  V get value {
    final Parameters owner =
        _schema ??
        (throw StateError(
          'Parameter "${draft.names.first}" is not listed in the declared '
          'parameters of a schema, so it was never loaded',
        ));
    return owner.valueOf(this) as V;
  }
}
