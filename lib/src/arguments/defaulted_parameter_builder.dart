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

/// Declares a parameter of type [T] that falls back to a fixed value.
///
/// The value reads as `T`. The default is not converted, because it was
/// written in Dart rather than typed by a user, but it is held to the
/// constraint its conversion installed - the allowed values of `choice`,
/// the checks of `path` and `file` - and to the rules declared through
/// [validate].
final class DefaultedParameterBuilder<T> extends DeclaredParameter<T> {
  /// Creates the builder of [draft] on [schema], falling back to
  /// [_fallback].
  @internal
  DefaultedParameterBuilder(super.schema, super.draft, this._fallback);

  /// The value used when no source supplies one.
  final T _fallback;

  /// Always [Cardinality.defaulted].
  @internal
  @override
  Cardinality get cardinality => Cardinality.defaulted;

  /// The declared default.
  @internal
  @override
  Object? get defaultValue => _fallback;

  /// Adds [rule], which the converted value has to satisfy.
  ///
  /// Returns a builder carrying the additional rule.
  DefaultedParameterBuilder<T> validate(
    void Function(ValidationScope it, T value) rule,
  ) => DefaultedParameterBuilder<T>(
    schema,
    draft.withValidator((scope, value) => rule(scope, value as T)),
    _fallback,
  );

  /// Marks the value as secret, so that Essentia masks it wherever it
  /// renders it.
  ///
  /// Returns a builder whose parameter is masked in all output.
  DefaultedParameterBuilder<T> sensitive() =>
      DefaultedParameterBuilder<T>(schema, draft.asSensitive(), _fallback);

  /// Reads the value from the environment [variable] when it was not passed
  /// on the command line.
  ///
  /// Returns a builder bound to that variable.
  DefaultedParameterBuilder<T> env(String variable) =>
      DefaultedParameterBuilder<T>(
        schema,
        draft.withEnvironment(variable),
        _fallback,
      );

  /// Excludes the parameter from the environment fallback its schema would
  /// otherwise derive.
  ///
  /// Returns a builder that is only ever fed from the command line.
  DefaultedParameterBuilder<T> noEnv() => DefaultedParameterBuilder<T>(
    schema,
    draft.withoutEnvironment(),
    _fallback,
  );

  /// Sets the one-line [description] shown in the usage listing.
  ///
  /// Returns a builder carrying the description.
  DefaultedParameterBuilder<T> describedAs(String description) =>
      DefaultedParameterBuilder<T>(
        schema,
        draft.withDescription(description),
        _fallback,
      );

  /// Marks the parameter as still honoured but no longer to be used.
  ///
  /// Giving it produces a warning rather than an error. [advice] says what
  /// to use instead.
  ///
  /// Returns a builder whose parameter is marked deprecated.
  DefaultedParameterBuilder<T> deprecated([String advice = '']) =>
      DefaultedParameterBuilder<T>(
        schema,
        draft.asDeprecated(advice),
        _fallback,
      );
}
