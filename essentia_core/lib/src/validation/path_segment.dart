/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// One step of a violation path.
@immutable
sealed class PathSegment {
  /// Creates a segment.
  const PathSegment();
}

/// A named step, usually a property.
final class NameSegment extends PathSegment {
  /// Creates the step named [value].
  const NameSegment(this.value);

  /// The name.
  final String value;

  /// Two named steps are equal when their names are.
  @override
  bool operator ==(Object other) =>
      other is NameSegment && value == other.value;

  /// The hash of the name.
  @override
  int get hashCode => value.hashCode;

  /// Renders the step as its plain name.
  @override
  String toString() => value;
}

/// A position in a list.
final class IndexSegment extends PathSegment {
  /// Creates the step at the zero-based position [value].
  const IndexSegment(this.value);

  /// The zero-based position.
  final int value;

  /// Two positions are equal when their values are.
  @override
  bool operator ==(Object other) =>
      other is IndexSegment && value == other.value;

  /// The hash of the position.
  @override
  int get hashCode => value.hashCode;

  /// Renders the step as `[value]`.
  @override
  String toString() => '[$value]';
}

/// A key in a map.
final class KeySegment extends PathSegment {
  /// Creates the step under the map key [value].
  const KeySegment(this.value);

  /// The key.
  final String value;

  /// Two keys are equal when their values are.
  @override
  bool operator ==(Object other) => other is KeySegment && value == other.value;

  /// The hash of the key, kept apart from the hash of an equally named
  /// step.
  @override
  int get hashCode => Object.hash(KeySegment, value);

  /// Renders the step as `["value"]`.
  @override
  String toString() => '["$value"]';
}
