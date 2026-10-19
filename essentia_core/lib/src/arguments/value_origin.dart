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

import 'package:essentia_core/src/arguments/parameter_info.dart';
import 'package:meta/meta.dart';

/// Where a value came from.
///
/// This exists so that a report names the place the reader has to go and
/// fix something. A bad value that arrived through `APP_PORT` is reported
/// as `APP_PORT`, not as `--port`, because the command line is not where
/// it is wrong.
///
/// Every member has value semantics, so an origin can be compared with `==`
/// against one a caller builds: `origin == const ExternalOrigin('vault')`
/// is true for a value that source supplied.
@immutable
sealed class ValueOrigin {
  /// Creates an origin.
  const ValueOrigin();

  /// The value was passed as a program argument.
  static const ValueOrigin commandLine = CommandLineOrigin();

  /// The value is the declared default.
  static const ValueOrigin defaulted = DefaultOrigin();

  /// Renders the label under which a problem with a value from this origin
  /// is reported, for the value resolved for [parameter].
  ///
  /// Returns the label to print.
  String label(ParameterInfo parameter);
}

/// The value was passed as a program argument.
final class CommandLineOrigin extends ValueOrigin {
  /// Creates the origin.
  const CommandLineOrigin();

  /// The parameter's primary name.
  @override
  String label(ParameterInfo parameter) => parameter.primaryName;

  /// Every command line origin is the same.
  @override
  bool operator ==(Object other) => other is CommandLineOrigin;

  /// The hash shared by every command line origin.
  @override
  int get hashCode => (CommandLineOrigin).hashCode;

  /// `CommandLineOrigin`.
  @override
  String toString() => 'CommandLineOrigin';
}

/// The value was read from an environment variable.
final class EnvironmentOrigin extends ValueOrigin {
  /// Creates the origin of a value read from [variable].
  const EnvironmentOrigin(this.variable);

  /// The name of the environment variable.
  final String variable;

  /// The variable's name.
  @override
  String label(ParameterInfo parameter) => variable;

  /// Two environment origins are equal when they name the same variable.
  @override
  bool operator ==(Object other) =>
      other is EnvironmentOrigin && variable == other.variable;

  /// The hash of the variable.
  @override
  int get hashCode => variable.hashCode;

  /// `EnvironmentOrigin(APP_PORT)`.
  @override
  String toString() => 'EnvironmentOrigin($variable)';
}

/// The value was read from a value source supplied by the application.
final class ExternalOrigin extends ValueOrigin {
  /// Creates the origin of a value read from the source [sourceName].
  const ExternalOrigin(this.sourceName);

  /// The name the source reports itself under.
  final String sourceName;

  /// The parameter's primary name and the source: `--token (from vault)`.
  @override
  String label(ParameterInfo parameter) =>
      '${parameter.primaryName} (from $sourceName)';

  /// Two external origins are equal when they name the same source.
  @override
  bool operator ==(Object other) =>
      other is ExternalOrigin && sourceName == other.sourceName;

  /// The hash of the source name.
  @override
  int get hashCode => sourceName.hashCode;

  /// `ExternalOrigin(vault)`.
  @override
  String toString() => 'ExternalOrigin($sourceName)';
}

/// The value is the declared default rather than something that was passed
/// in.
final class DefaultOrigin extends ValueOrigin {
  /// Creates the origin.
  const DefaultOrigin();

  /// The parameter's primary name, marked as the default.
  @override
  String label(ParameterInfo parameter) => '${parameter.primaryName} (default)';

  /// Every default origin is the same.
  @override
  bool operator ==(Object other) => other is DefaultOrigin;

  /// The hash shared by every default origin.
  @override
  int get hashCode => (DefaultOrigin).hashCode;

  /// `DefaultOrigin`.
  @override
  String toString() => 'DefaultOrigin';
}
