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

/// Declares a parameter of type [T] that must be supplied by some source.
///
/// The value reads as `T`. When no source provides one, loading fails with
/// a missing parameter rather than the value being `null` later on.
final class RequiredParameterBuilder<T> extends DeclaredParameter<T> {
  /// Creates the builder of [draft] on [schema].
  @internal
  RequiredParameterBuilder(super.schema, super.draft);

  /// Always [Cardinality.required].
  @internal
  @override
  Cardinality get cardinality => Cardinality.required;

  /// Always `null`.
  @internal
  @override
  Object? get defaultValue => null;

  /// Adds [rule], which the converted value has to satisfy.
  ///
  /// Returns a builder carrying the additional rule.
  RequiredParameterBuilder<T> validate(
    void Function(ValidationScope it, T value) rule,
  ) => RequiredParameterBuilder<T>(
    schema,
    draft.withValidator((scope, value) => rule(scope, value as T)),
  );

  /// Marks the value as secret, so that Essentia masks it wherever it
  /// renders it.
  ///
  /// Returns a builder whose parameter is masked in all output.
  RequiredParameterBuilder<T> sensitive() =>
      RequiredParameterBuilder<T>(schema, draft.asSensitive());

  /// Reads the value from the environment [variable] when it was not passed
  /// on the command line.
  ///
  /// Returns a builder bound to that variable.
  RequiredParameterBuilder<T> env(String variable) =>
      RequiredParameterBuilder<T>(schema, draft.withEnvironment(variable));

  /// Excludes the parameter from the environment fallback its schema would
  /// otherwise derive.
  ///
  /// Returns a builder that is only ever fed from the command line.
  RequiredParameterBuilder<T> noEnv() =>
      RequiredParameterBuilder<T>(schema, draft.withoutEnvironment());

  /// Sets the one-line [description] shown in the usage listing.
  ///
  /// Returns a builder carrying the description.
  RequiredParameterBuilder<T> describedAs(String description) =>
      RequiredParameterBuilder<T>(schema, draft.withDescription(description));

  /// Marks the parameter as still honoured but no longer to be used.
  ///
  /// Giving it produces a warning rather than an error. [advice] says what
  /// to use instead.
  ///
  /// Returns a builder whose parameter is marked deprecated.
  RequiredParameterBuilder<T> deprecated([String advice = '']) =>
      RequiredParameterBuilder<T>(schema, draft.asDeprecated(advice));
}
