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

import 'package:meta/meta.dart';

/// The public description of a declared parameter, without its type.
///
/// This is what value sources, violations and the usage listing work
/// against. It deliberately carries no type information, so that
/// everything reporting on a parameter can do so without being generic.
@immutable
final class ParameterInfo {
  /// Creates the description of a parameter answering to [names].
  @internal
  ParameterInfo({
    required List<String> names,
    required this.environmentVariable,
    required this.typeName,
    required this.isRequired,
    required this.isSensitive,
    required this.acceptsMultiple,
    required this.isFlag,
    required this.defaultDisplay,
    required this.description,
    required this.deprecation,
  }) : names = List<String>.unmodifiable(names);

  /// Every name the parameter answers to, in declaration order, including
  /// the leading dashes.
  final List<String> names;

  /// The environment variable consulted when no value was passed on the
  /// command line, or `null` when the parameter has no environment
  /// fallback.
  final String? environmentVariable;

  /// The name of the type the parameter converts to, for display in the
  /// usage listing.
  final String typeName;

  /// Whether loading fails when the parameter is absent from every source.
  final bool isRequired;

  /// Whether the value is masked wherever Essentia renders it.
  final bool isSensitive;

  /// Whether the parameter collects every occurrence instead of expecting
  /// exactly one.
  final bool acceptsMultiple;

  /// Whether the parameter is a flag, meaning it takes no value of its own.
  final bool isFlag;

  /// The default rendered for the usage listing, or `null` when the
  /// parameter has no default.
  final String? defaultDisplay;

  /// The one-line explanation shown in the usage listing, or `null` when
  /// none was given.
  final String? description;

  /// What to use instead of this parameter, or `null` when it is not
  /// deprecated.
  ///
  /// An empty string marks the parameter deprecated without pointing
  /// anywhere.
  final String? deprecation;

  /// The first declared name, used whenever a single name has to stand for
  /// the parameter.
  String get primaryName => names.first;

  /// The [primaryName].
  @override
  String toString() => primaryName;
}
