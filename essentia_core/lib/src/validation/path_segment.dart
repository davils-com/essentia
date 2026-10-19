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
