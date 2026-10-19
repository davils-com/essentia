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
import 'package:essentia_core/src/arguments/declared_parameter.dart';
import 'package:essentia_core/src/validation/validation_scope.dart';
import 'package:meta/meta.dart';

/// Declares a parameter of type [T] that must be supplied by some source.
///
/// The value reads as `T`. When no source provides one, loading fails with
/// a missing parameter rather than the value being `null` later on.
final class RequiredParameterBuilder<T> extends DeclaredParameter<T> {
  /// Creates the builder of [draft].
  @internal
  RequiredParameterBuilder(super.draft);

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
    draft.withValidator((scope, value) => rule(scope, value as T)),
  );

  /// Marks the value as secret, so that Essentia masks it wherever it
  /// renders it.
  ///
  /// Returns a builder whose parameter is masked in all output.
  RequiredParameterBuilder<T> sensitive() =>
      RequiredParameterBuilder<T>(draft.asSensitive());

  /// Reads the value from the environment [variable] when it was not passed
  /// on the command line.
  ///
  /// Returns a builder bound to that variable.
  RequiredParameterBuilder<T> env(String variable) =>
      RequiredParameterBuilder<T>(draft.withEnvironment(variable));

  /// Excludes the parameter from the environment fallback its schema would
  /// otherwise derive.
  ///
  /// Returns a builder that is only ever fed from the command line.
  RequiredParameterBuilder<T> noEnv() =>
      RequiredParameterBuilder<T>(draft.withoutEnvironment());

  /// Sets the one-line [description] shown in the usage listing.
  ///
  /// Returns a builder carrying the description.
  RequiredParameterBuilder<T> describedAs(String description) =>
      RequiredParameterBuilder<T>(draft.withDescription(description));

  /// Marks the parameter as still honoured but no longer to be used.
  ///
  /// Giving it produces a warning rather than an error. [advice] says what
  /// to use instead.
  ///
  /// Returns a builder whose parameter is marked deprecated.
  RequiredParameterBuilder<T> deprecated([String advice = '']) =>
      RequiredParameterBuilder<T>(draft.asDeprecated(advice));
}
