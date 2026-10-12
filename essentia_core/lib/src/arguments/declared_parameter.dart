/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
