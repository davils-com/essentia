/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/version/internal/version_steps.dart';
import 'package:essentia_core/src/version/semantic_version.dart';
import 'package:essentia_core/src/version/version_interval.dart';
import 'package:meta/meta.dart';

/// The interval of every version there is.
@internal
final everything = VersionInterval(null, null, startExclusive: false);

/// The interval from [start] up to [end], exclusive, in the one stored
/// form: a bound is kept without build metadata, and an exclusive
/// pre-release lower bound is stored as its inclusive successor.
///
/// [startExclusive] says whether [start] itself is left out; it is ignored
/// without a lower bound.
///
/// Returns the interval, or `null` when no version lies inside it.
@internal
VersionInterval? interval(
  SemanticVersion? start,
  SemanticVersion? end, {
  bool startExclusive = false,
}) {
  final SemanticVersion? to = end?.withoutBuild();
  if (to == minimum) {
    return null;
  }
  final SemanticVersion? from = start?.withoutBuild();
  if (from == null) {
    return VersionInterval(null, to, startExclusive: false);
  }
  final bool exclusiveRelease = startExclusive && !from.isPreRelease;
  final SemanticVersion? stored = startExclusive && from.isPreRelease
      ? successor(from)
      : from;
  if (stored == null) {
    return null;
  }
  final SemanticVersion? first = exclusiveRelease ? successor(from) : stored;
  if (first == null) {
    return null;
  }
  if (to != null && first >= to) {
    return null;
  }
  return VersionInterval(stored, to, startExclusive: exclusiveRelease);
}

/// The interval between [lower] and [upper], bound by bound, each of them
/// inside when [lowerInclusive] or [upperInclusive] says so.
///
/// Returns the interval, or `null` when no version lies inside it.
@internal
VersionInterval? bounded({
  required SemanticVersion? lower,
  required bool lowerInclusive,
  required SemanticVersion? upper,
  required bool upperInclusive,
}) {
  final SemanticVersion? end = upper == null || !upperInclusive
      ? upper
      : successor(upper);
  return interval(lower, end, startExclusive: !lowerInclusive);
}

/// Sorts [intervals] by where they start and merges those that overlap or
/// touch.
///
/// Returns the disjoint intervals in ascending order.
@internal
List<VersionInterval> normalized(List<VersionInterval> intervals) {
  final merged = <VersionInterval>[];
  final sorted = <VersionInterval>[...intervals]..sort(_byStart);
  for (final next in sorted) {
    final VersionInterval? last = merged.lastOrNull;
    if (last == null || !_reaches(last, next)) {
      merged.add(next);
      continue;
    }
    merged[merged.length - 1] = VersionInterval(
      last.start,
      _laterEnd(last.end, next.end),
      startExclusive: last.startExclusive,
    );
  }
  return merged;
}

/// The versions in both [left] and [right].
///
/// Returns the intersection as disjoint intervals in ascending order.
@internal
List<VersionInterval> intersection(
  List<VersionInterval> left,
  List<VersionInterval> right,
) => normalized(<VersionInterval>[
  for (final first in left)
    for (final second in right) ?overlap(first, second),
]);

/// The versions in both [first] and [second].
///
/// Returns the overlap, or `null` when they share no version.
@internal
VersionInterval? overlap(VersionInterval first, VersionInterval second) {
  final VersionInterval later = _laterStarting(first, second);
  return interval(
    later.start,
    _earlierEnd(first.end, second.end),
    startExclusive: later.startExclusive,
  );
}

/// Orders intervals by their first version, unbounded ones first, and an
/// inclusive start before an exclusive one.
///
/// Returns a negative number, zero or a positive number when [left] starts
/// before, with or after [right].
int _byStart(VersionInterval left, VersionInterval right) {
  final int byFirst = _compareStarts(left.first, right.first);
  if (byFirst != 0) {
    return byFirst;
  }
  if (left.startExclusive == right.startExclusive) {
    return 0;
  }
  return left.startExclusive ? 1 : -1;
}

/// Compares the starts [left] and [right], `null` - no lower bound - first,
/// Kotlin's `compareValues`.
///
/// Returns a negative number, zero or a positive number when [left] comes
/// before, with or after [right].
int _compareStarts(SemanticVersion? left, SemanticVersion? right) {
  if (left == null && right == null) {
    return 0;
  }
  if (left == null) {
    return -1;
  }
  if (right == null) {
    return 1;
  }
  return left.compareTo(right);
}

/// Whether [later] starts no later than right after [earlier] ends, so
/// that the two can be merged into one.
///
/// Returns `true` when they overlap or touch.
bool _reaches(VersionInterval earlier, VersionInterval later) {
  final SemanticVersion? end = earlier.end;
  final SemanticVersion? start = later.first;
  if (end == null || start == null) {
    return true;
  }
  return start <= end;
}

/// The one of [first] and [second] that starts later, the exclusive one
/// when both start at the same version.
///
/// Returns that interval.
VersionInterval _laterStarting(VersionInterval first, VersionInterval second) {
  final int order = _compareStarts(first.first, second.first);
  if (order > 0) {
    return first;
  }
  if (order < 0) {
    return second;
  }
  if (first.startExclusive) {
    return second;
  }
  return first;
}

/// The earlier of the ends [first] and [second], where `null` is no end.
///
/// Returns the end, or `null` when neither has one.
SemanticVersion? _earlierEnd(SemanticVersion? first, SemanticVersion? second) {
  if (first == null) {
    return second;
  }
  if (second == null) {
    return first;
  }
  return first <= second ? first : second;
}

/// The later of the ends [first] and [second], where `null` is no end.
///
/// Returns the end, or `null` when either has none.
SemanticVersion? _laterEnd(SemanticVersion? first, SemanticVersion? second) {
  if (first == null || second == null) {
    return null;
  }
  return first >= second ? first : second;
}
