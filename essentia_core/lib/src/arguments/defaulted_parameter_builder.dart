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

/// Declares a parameter of type [T] that falls back to a fixed value.
///
/// The value reads as `T`. The default is not converted, because it was
/// written in Dart rather than typed by a user, but it is held to the
/// constraint its conversion installed - the allowed values of `choice`,
/// the checks of `path` and `file` - and to the rules declared through
/// [validate].
final class DefaultedParameterBuilder<T> extends DeclaredParameter<T> {
  /// Creates the builder of [draft], falling back to
  /// [_fallback].
  @internal
  DefaultedParameterBuilder(super.draft, this._fallback);

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
    draft.withValidator((scope, value) => rule(scope, value as T)),
    _fallback,
  );

  /// Marks the value as secret, so that Essentia masks it wherever it
  /// renders it.
  ///
  /// Returns a builder whose parameter is masked in all output.
  DefaultedParameterBuilder<T> sensitive() =>
      DefaultedParameterBuilder<T>(draft.asSensitive(), _fallback);

  /// Reads the value from the environment [variable] when it was not passed
  /// on the command line.
  ///
  /// Returns a builder bound to that variable.
  DefaultedParameterBuilder<T> env(String variable) =>
      DefaultedParameterBuilder<T>(draft.withEnvironment(variable), _fallback);

  /// Excludes the parameter from the environment fallback its schema would
  /// otherwise derive.
  ///
  /// Returns a builder that is only ever fed from the command line.
  DefaultedParameterBuilder<T> noEnv() =>
      DefaultedParameterBuilder<T>(draft.withoutEnvironment(), _fallback);

  /// Sets the one-line [description] shown in the usage listing.
  ///
  /// Returns a builder carrying the description.
  DefaultedParameterBuilder<T> describedAs(String description) =>
      DefaultedParameterBuilder<T>(
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
      DefaultedParameterBuilder<T>(draft.asDeprecated(advice), _fallback);
}
