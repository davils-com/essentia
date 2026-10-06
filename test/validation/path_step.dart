/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
import 'package:meta/meta.dart';

/// One generated step of a violation path, the model the path property
/// tests compare the real path against.
@immutable
sealed class PathStep {
  /// Creates a step.
  const PathStep();

  /// Appends this step to [path].
  ///
  /// Returns the path one step deeper.
  ViolationPath appendTo(ViolationPath path);

  /// How this step renders on its own.
  String get rendered;
}

/// A named step.
final class NamedStep extends PathStep {
  /// Creates the step named [value].
  const NamedStep(this.value);

  /// The name.
  final String value;

  /// Appends the name to [path].
  @override
  ViolationPath appendTo(ViolationPath path) => path.name(value);

  /// The plain name.
  @override
  String get rendered => value;

  /// Two named steps are equal when their names are.
  @override
  bool operator ==(Object other) => other is NamedStep && value == other.value;

  /// The hash of the name.
  @override
  int get hashCode => Object.hash(NamedStep, value);

  /// Renders the step for a failure message.
  @override
  String toString() => 'Named($value)';
}

/// A list position.
final class IndexStep extends PathStep {
  /// Creates the step at position [value].
  const IndexStep(this.value);

  /// The position.
  final int value;

  /// Appends the position to [path].
  @override
  ViolationPath appendTo(ViolationPath path) => path.index(value);

  /// The position in brackets.
  @override
  String get rendered => '[$value]';

  /// Two positions are equal when their values are.
  @override
  bool operator ==(Object other) => other is IndexStep && value == other.value;

  /// The hash of the position.
  @override
  int get hashCode => Object.hash(IndexStep, value);

  /// Renders the step for a failure message.
  @override
  String toString() => 'At($value)';
}

/// A map key.
final class KeyedStep extends PathStep {
  /// Creates the step under the key [value].
  const KeyedStep(this.value);

  /// The key.
  final String value;

  /// Appends the key to [path].
  @override
  ViolationPath appendTo(ViolationPath path) => path.key(value);

  /// The key in quoted brackets.
  @override
  String get rendered => '["$value"]';

  /// Two keys are equal when their values are.
  @override
  bool operator ==(Object other) => other is KeyedStep && value == other.value;

  /// The hash of the key.
  @override
  int get hashCode => Object.hash(KeyedStep, value);

  /// Renders the step for a failure message.
  @override
  String toString() => 'Keyed($value)';
}
