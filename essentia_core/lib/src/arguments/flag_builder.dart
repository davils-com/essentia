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
import 'package:meta/meta.dart';

/// Declares a parameter that carries no value of its own.
///
/// Naming the flag turns it on, so `--dry-run` reads as `true` and its
/// absence as `false`. An explicit value is still accepted where a script
/// finds it easier to always pass the parameter: `--dry-run=false` reads as
/// `false`.
final class FlagBuilder extends DeclaredParameter<bool> {
  /// Creates the builder of [draft], reading [_fallback] when
  /// the flag is not given.
  @internal
  FlagBuilder(super.draft, {this._fallback = false});

  /// The value of the flag when it is not given.
  final bool _fallback;

  /// Always [Cardinality.defaulted].
  @internal
  @override
  Cardinality get cardinality => Cardinality.defaulted;

  /// The value of the flag when it is not given.
  @internal
  @override
  Object? get defaultValue => _fallback;

  /// Also accepts the `--no-` form of every long name, which sets the flag
  /// to `false`.
  ///
  /// This is what lets a wrapper script turn off something the schema
  /// defaults to on.
  ///
  /// Returns a builder that answers to its negated names as well.
  FlagBuilder negatable() =>
      FlagBuilder(draft.asNegatable(), fallback: _fallback);

  /// Makes the flag `true` when it is not given, which is mostly useful
  /// together with [negatable].
  ///
  /// Returns a builder carrying the default.
  FlagBuilder enabledByDefault() => FlagBuilder(draft, fallback: true);

  /// Reads the value from the environment [variable] when the flag was not
  /// passed on the command line.
  ///
  /// Returns a builder bound to that variable.
  FlagBuilder env(String variable) =>
      FlagBuilder(draft.withEnvironment(variable), fallback: _fallback);

  /// Excludes the flag from the environment fallback its schema would
  /// otherwise derive.
  ///
  /// Returns a builder that is only ever fed from the command line.
  FlagBuilder noEnv() =>
      FlagBuilder(draft.withoutEnvironment(), fallback: _fallback);

  /// Sets the one-line [description] shown in the usage listing.
  ///
  /// Returns a builder carrying the description.
  FlagBuilder describedAs(String description) =>
      FlagBuilder(draft.withDescription(description), fallback: _fallback);

  /// Marks the flag as still honoured but no longer to be used.
  ///
  /// Giving it produces a warning rather than an error. [advice] says what
  /// to use instead.
  ///
  /// Returns a builder whose flag is marked deprecated.
  FlagBuilder deprecated([String advice = '']) =>
      FlagBuilder(draft.asDeprecated(advice), fallback: _fallback);
}
