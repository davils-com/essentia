/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/validation/path_segment.dart';
import 'package:meta/meta.dart';

/// Where a violation happened, as a path through the object being
/// validated.
///
/// A path is what turns "the queue size must be positive" into something
/// actionable: `sinks[2].async.queueSize` names the one place to go and
/// change. Paths are built by appending segments, and nesting a validation
/// prefixes everything it reports.
///
/// A path is also allowed to be a single plain name that is not a property
/// at all, such as `--port` or `APP_PORT`, because the same report has to
/// serve configuration objects and program arguments.
///
/// Instances are immutable; every appending operation returns a new path.
@immutable
final class ViolationPath {
  /// Creates a path from its [segments], outermost first.
  const ViolationPath._(this.segments);

  /// A path consisting of the single name [value].
  factory ViolationPath.of(String value) => root.name(value);

  /// The path of the object as a whole, which renders as the empty string.
  static const root = ViolationPath._(<PathSegment>[]);

  /// The separator rendered between two named steps.
  static const _separator = '.';

  /// The segments, outermost first.
  final List<PathSegment> segments;

  /// Whether this path points at the object as a whole rather than at
  /// anything inside it.
  bool get isRoot => segments.isEmpty;

  /// Appends the named step [value].
  ///
  /// Returns a path one step deeper.
  ViolationPath name(String value) => _append(NameSegment(value));

  /// Appends the zero-based list position [value].
  ///
  /// Returns a path one step deeper.
  ViolationPath index(int value) => _append(IndexSegment(value));

  /// Appends the map key [value].
  ///
  /// Returns a path one step deeper.
  ViolationPath key(String value) => _append(KeySegment(value));

  /// Appends every segment of [other], which is how a nested validation is
  /// reported under the place that nested it.
  ///
  /// Returns the combined path.
  ViolationPath operator +(ViolationPath other) => ViolationPath._(
    List<PathSegment>.unmodifiable(<PathSegment>[
      ...segments,
      ...other.segments,
    ]),
  );

  /// Two paths are equal when their segments are.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! ViolationPath) {
      return false;
    }
    return _sameSegments(other.segments);
  }

  /// The hash of the segments.
  @override
  int get hashCode => Object.hashAll(segments);

  /// Renders the path the way a person reads it: `sinks[2].queueSize`.
  @override
  String toString() {
    final rendered = StringBuffer();
    for (final PathSegment segment in segments) {
      final bool needsSeparator = segment is NameSegment && rendered.isNotEmpty;
      if (needsSeparator) {
        rendered.write(_separator);
      }
      rendered.write(segment);
    }
    return rendered.toString();
  }

  /// Appends [segment].
  ///
  /// Returns a path one step deeper.
  ViolationPath _append(PathSegment segment) => ViolationPath._(
    List<PathSegment>.unmodifiable(<PathSegment>[...segments, segment]),
  );

  /// Whether [others] holds the same segments as this path, in order.
  ///
  /// Returns `true` when both are equal element by element.
  bool _sameSegments(List<PathSegment> others) {
    if (others.length != segments.length) {
      return false;
    }
    for (var position = 0; position < segments.length; position++) {
      if (segments[position] != others[position]) {
        return false;
      }
    }
    return true;
  }
}
