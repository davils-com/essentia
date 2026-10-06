/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/arguments/cardinality.dart';
import 'package:essentia/src/arguments/parameter.dart';
import 'package:essentia/src/arguments/parameter_draft.dart';
import 'package:essentia/src/arguments/parameters.dart';
import 'package:meta/meta.dart';

/// What every builder of a parameter is: a declaration on one schema, and
/// the handle its value of type [V] is read through.
@internal
abstract class DeclaredParameter<V> implements Parameter<V> {
  /// Creates the declaration [draft] on [schema].
  DeclaredParameter(this.schema, this.draft);

  /// The schema the parameter is declared on.
  final Parameters schema;

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

  /// The resolved value, read from the schema's snapshot.
  @override
  V get value => schema.valueOf(this) as V;
}
