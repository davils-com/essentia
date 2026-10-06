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
import 'package:essentia/src/arguments/defaulted_parameter_builder.dart';
import 'package:essentia/src/arguments/multiple_parameter_builder.dart';
import 'package:essentia/src/arguments/required_parameter_builder.dart';
import 'package:essentia/src/validation/validation_scope.dart';
import 'package:meta/meta.dart';

/// Declares a parameter of type [T] that may be absent.
///
/// Used on its own the parameter reads as `T?`. The terminal calls change
/// that: [required] and [defaultsTo] make it non-null, [multiple] and
/// [split] turn it into a list.
final class ParameterBuilder<T> extends DeclaredParameter<T?> {
  /// Creates the builder of [draft] on [schema].
  @internal
  ParameterBuilder(super.schema, super.draft);

  /// Always [Cardinality.optional].
  @internal
  @override
  Cardinality get cardinality => Cardinality.optional;

  /// Always `null`.
  @internal
  @override
  Object? get defaultValue => null;

  /// Adds [rule], which the converted value has to satisfy.
  ///
  /// Rules are additive; every rule declared runs, and each failure is
  /// reported separately.
  ///
  /// Returns a builder carrying the additional rule.
  ParameterBuilder<T> validate(
    void Function(ValidationScope it, T value) rule,
  ) => ParameterBuilder<T>(
    schema,
    draft.withValidator((scope, value) => rule(scope, value as T)),
  );

  /// Marks the value as secret, so that Essentia masks it wherever it
  /// renders it.
  ///
  /// Returns a builder whose parameter is masked in all output.
  ParameterBuilder<T> sensitive() =>
      ParameterBuilder<T>(schema, draft.asSensitive());

  /// Reads the value from the environment [variable] when it was not passed
  /// on the command line.
  ///
  /// Returns a builder bound to that variable.
  ParameterBuilder<T> env(String variable) =>
      ParameterBuilder<T>(schema, draft.withEnvironment(variable));

  /// Excludes the parameter from the environment fallback its schema would
  /// otherwise derive.
  ///
  /// Returns a builder that is only ever fed from the command line.
  ParameterBuilder<T> noEnv() =>
      ParameterBuilder<T>(schema, draft.withoutEnvironment());

  /// Sets the one-line [description] shown in the usage listing.
  ///
  /// Returns a builder carrying the description.
  ParameterBuilder<T> describedAs(String description) =>
      ParameterBuilder<T>(schema, draft.withDescription(description));

  /// Marks the parameter as still honoured but no longer to be used.
  ///
  /// Giving it produces a warning rather than an error: the value is used
  /// and loading succeeds. [advice] says what to use instead and is left out
  /// when there is nothing to point at.
  ///
  /// Returns a builder whose parameter is marked deprecated.
  ParameterBuilder<T> deprecated([String advice = '']) =>
      ParameterBuilder<T>(schema, draft.asDeprecated(advice));

  /// Makes the parameter mandatory, so that the value reads as `T` rather
  /// than `T?`.
  ///
  /// Returns a builder for a mandatory parameter.
  RequiredParameterBuilder<T> required() =>
      RequiredParameterBuilder<T>(schema, draft);

  /// Supplies [value] for when no source provides one.
  ///
  /// The default is not converted, because it was written in Dart rather
  /// than typed by a user, but it is held to the same checks as a given
  /// value: the constraint a conversion such as `choice` or
  /// `path(mustExist: true)` installed, and every rule declared through
  /// [validate]. A default that fails one is reported by `load` under the
  /// default's origin.
  ///
  /// Returns a builder for a parameter that always has a value.
  DefaultedParameterBuilder<T> defaultsTo(T value) =>
      DefaultedParameterBuilder<T>(schema, draft, value);

  /// Collects every occurrence of the parameter instead of expecting a
  /// single one.
  ///
  /// Returns a builder whose value is a list.
  MultipleParameterBuilder<T> multiple() =>
      MultipleParameterBuilder<T>(schema, draft, null);

  /// Collects every occurrence and additionally splits each one on
  /// [delimiter].
  ///
  /// This is what turns `--tag=a,b --tag=c` into three values. [delimiter]
  /// is matched literally. An empty piece - from a trailing delimiter, or
  /// two in a row - is dropped rather than converted, so `--tag=a,b,` is
  /// two values.
  ///
  /// Returns a builder whose value is a list.
  ///
  /// Throws an [ArgumentError] if [delimiter] is empty, which would split
  /// between every character; a parameter that takes one value per
  /// occurrence is [multiple].
  MultipleParameterBuilder<T> split(String delimiter) =>
      MultipleParameterBuilder<T>(schema, draft.withSplit(delimiter), null);
}
