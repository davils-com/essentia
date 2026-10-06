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
import 'package:meta/meta.dart';

/// Declares a parameter that carries no value of its own.
///
/// Naming the flag turns it on, so `--dry-run` reads as `true` and its
/// absence as `false`. An explicit value is still accepted where a script
/// finds it easier to always pass the parameter: `--dry-run=false` reads as
/// `false`.
final class FlagBuilder extends DeclaredParameter<bool> {
  /// Creates the builder of [draft] on [schema], reading [_fallback] when
  /// the flag is not given.
  @internal
  FlagBuilder(super.schema, super.draft, {this._fallback = false});

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
      FlagBuilder(schema, draft.asNegatable(), fallback: _fallback);

  /// Makes the flag `true` when it is not given, which is mostly useful
  /// together with [negatable].
  ///
  /// Returns a builder carrying the default.
  FlagBuilder enabledByDefault() => FlagBuilder(schema, draft, fallback: true);

  /// Reads the value from the environment [variable] when the flag was not
  /// passed on the command line.
  ///
  /// Returns a builder bound to that variable.
  FlagBuilder env(String variable) =>
      FlagBuilder(schema, draft.withEnvironment(variable), fallback: _fallback);

  /// Excludes the flag from the environment fallback its schema would
  /// otherwise derive.
  ///
  /// Returns a builder that is only ever fed from the command line.
  FlagBuilder noEnv() =>
      FlagBuilder(schema, draft.withoutEnvironment(), fallback: _fallback);

  /// Sets the one-line [description] shown in the usage listing.
  ///
  /// Returns a builder carrying the description.
  FlagBuilder describedAs(String description) => FlagBuilder(
    schema,
    draft.withDescription(description),
    fallback: _fallback,
  );

  /// Marks the flag as still honoured but no longer to be used.
  ///
  /// Giving it produces a warning rather than an error. [advice] says what
  /// to use instead.
  ///
  /// Returns a builder whose flag is marked deprecated.
  FlagBuilder deprecated([String advice = '']) =>
      FlagBuilder(schema, draft.asDeprecated(advice), fallback: _fallback);
}
