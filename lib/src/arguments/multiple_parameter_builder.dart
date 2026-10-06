/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/arguments/cardinality.dart';
import 'package:essentia/src/arguments/declared_parameter.dart';
import 'package:essentia/src/validation/validation_scope.dart';
import 'package:meta/meta.dart';

/// Declares a parameter that collects every occurrence of type [T].
///
/// The value reads as `List<T>`, empty when nothing was given and no
/// default was declared. Rules added through [validate] run against each
/// element rather than the list.
final class MultipleParameterBuilder<T> extends DeclaredParameter<List<T>> {
  /// Creates the builder of [draft] on [schema], falling back to
  /// [_fallback] or to an empty list when it is `null`.
  @internal
  MultipleParameterBuilder(super.schema, super.draft, this._fallback);

  /// The list used when no source supplies any value, or `null` for an
  /// empty one.
  final List<T>? _fallback;

  /// Always [Cardinality.multiple].
  @internal
  @override
  Cardinality get cardinality => Cardinality.multiple;

  /// The declared default list, or `null`.
  @internal
  @override
  Object? get defaultValue => _fallback;

  /// Collects the resolved [values] into a list of [T].
  ///
  /// Returns an unmodifiable list of [T].
  @internal
  @override
  List<Object?> collect(List<Object?> values) =>
      List<T>.unmodifiable(values.cast<T>());

  /// Adds [rule], which every element has to satisfy.
  ///
  /// Returns a builder carrying the additional rule.
  MultipleParameterBuilder<T> validate(
    void Function(ValidationScope it, T value) rule,
  ) => MultipleParameterBuilder<T>(
    schema,
    draft.withValidator((scope, value) => rule(scope, value as T)),
    _fallback,
  );

  /// Marks the values as secret, so that Essentia masks them wherever it
  /// renders them.
  ///
  /// Returns a builder whose parameter is masked in all output.
  MultipleParameterBuilder<T> sensitive() =>
      MultipleParameterBuilder<T>(schema, draft.asSensitive(), _fallback);

  /// Reads the values from the environment [variable] when none were passed
  /// on the command line.
  ///
  /// A single environment variable holds a single occurrence. Declaring
  /// [split] as well is what lets one variable carry several values.
  ///
  /// Returns a builder bound to that variable.
  MultipleParameterBuilder<T> env(String variable) =>
      MultipleParameterBuilder<T>(
        schema,
        draft.withEnvironment(variable),
        _fallback,
      );

  /// Excludes the parameter from the environment fallback its schema would
  /// otherwise derive.
  ///
  /// Returns a builder that is only ever fed from the command line.
  MultipleParameterBuilder<T> noEnv() => MultipleParameterBuilder<T>(
    schema,
    draft.withoutEnvironment(),
    _fallback,
  );

  /// Sets the one-line [description] shown in the usage listing.
  ///
  /// Returns a builder carrying the description.
  MultipleParameterBuilder<T> describedAs(String description) =>
      MultipleParameterBuilder<T>(
        schema,
        draft.withDescription(description),
        _fallback,
      );

  /// Splits each occurrence on [delimiter] before converting the pieces.
  ///
  /// [delimiter] is matched literally. An empty piece - from a trailing
  /// delimiter, or two in a row - is dropped rather than converted.
  ///
  /// Returns a builder that splits its occurrences.
  ///
  /// Throws an [ArgumentError] if [delimiter] is empty, which would split
  /// between every character.
  MultipleParameterBuilder<T> split(String delimiter) =>
      MultipleParameterBuilder<T>(
        schema,
        draft.withSplit(delimiter),
        _fallback,
      );

  /// Supplies the list [value] for when no source provides any value.
  ///
  /// Returns a builder carrying the default.
  MultipleParameterBuilder<T> defaultsTo(List<T> value) =>
      MultipleParameterBuilder<T>(schema, draft, List<T>.unmodifiable(value));

  /// Marks the parameter as still honoured but no longer to be used.
  ///
  /// Giving it produces a warning rather than an error. [advice] says what
  /// to use instead.
  ///
  /// Returns a builder whose parameter is marked deprecated.
  MultipleParameterBuilder<T> deprecated([String advice = '']) =>
      MultipleParameterBuilder<T>(
        schema,
        draft.asDeprecated(advice),
        _fallback,
      );
}
