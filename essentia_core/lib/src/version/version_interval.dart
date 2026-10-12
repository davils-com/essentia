/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/version/internal/version_steps.dart';
import 'package:essentia_core/src/version/pre_release_policy.dart';
import 'package:essentia_core/src/version/semantic_version.dart';
import 'package:essentia_core/src/version/semantic_version_range.dart';
import 'package:meta/meta.dart';

/// What opens an interval that holds its lower bound.
const _inclusiveLower = '[';

/// What opens an interval that leaves its lower bound out.
const _exclusiveLower = '(';

/// What closes an interval that holds its upper bound.
const _inclusiveUpper = ']';

/// What closes an interval that leaves its upper bound out.
const _exclusiveUpper = ')';

/// What separates the two bounds.
const _boundSeparator = ',';

/// One unbroken stretch of versions inside a [SemanticVersionRange].
///
/// A range is a set of these, disjoint and in ascending order -
/// `^1.2 || ^3` is two of them, because the versions from `2.0.0-0` up to
/// `3.0.0` lie between. An interval is only ever obtained from a range,
/// through [SemanticVersionRange.intervals].
///
/// ## One set, one form
///
/// Versions are discrete: nothing lies between `1.2.3-rc` and
/// `1.2.3-rc.0`, or between `1.2.3` and `1.2.4-0`, so `<=1.2.3` and
/// `<1.2.4-0` are the same set. An interval stores such a bound once, and
/// [lower], [upper] and [toString] state it in the form that names the
/// version a person wrote: `<=1.2.3` reads back as `1.2.3]`, not as
/// `1.2.4-0)`. Two intervals are equal exactly when they hold the same
/// versions and name the same pre-releases.
///
/// That last clause keeps one pair apart: `>1.2.3` and `>=1.2.4-0` hold the
/// same versions, but only the second names a pre-release of 1.2.4, so
/// [PreReleasePolicy.sameCoreOnly] admits `1.2.4-beta` into the second and
/// not into the first. They are two intervals, and each reads back as
/// written.
///
/// Build metadata never appears in a bound. Precedence ignores it, so a
/// bound written with some has it dropped rather than kept as a
/// distinction that decides nothing.
@immutable
final class VersionInterval {
  /// Creates the interval from [start] up to [end], exclusive, leaving
  /// [start] itself out when [startExclusive]; `null` is no bound.
  @internal
  VersionInterval(this.start, this.end, {required this.startExclusive})
    : first = startExclusive && start != null ? successor(start) : start,
      lower = start == null ? null : preReleasePredecessor(start) ?? start,
      lowerInclusive =
          start != null &&
          !startExclusive &&
          preReleasePredecessor(start) == null,
      upper = end == null ? null : predecessor(end) ?? end,
      upperInclusive = end != null && predecessor(end) != null;

  /// The stored lower bound, or `null` when unbounded below.
  @internal
  final SemanticVersion? start;

  /// Whether [start] itself is left out; only ever `true` for a release.
  @internal
  final bool startExclusive;

  /// The first version above the interval, or `null` when unbounded above.
  @internal
  final SemanticVersion? end;

  /// The first version inside, or `null` when unbounded below.
  @internal
  final SemanticVersion? first;

  /// The lower bound, or `null` when the interval is unbounded below.
  final SemanticVersion? lower;

  /// Whether [lower] itself is inside. `false` without a lower bound.
  final bool lowerInclusive;

  /// The upper bound, or `null` when the interval is unbounded above.
  final SemanticVersion? upper;

  /// Whether [upper] itself is inside. `false` without an upper bound.
  final bool upperInclusive;

  /// Whether [version] lies inside, by precedence.
  ///
  /// Returns `true` when it is on the right side of both bounds.
  bool contains(SemanticVersion version) {
    final SemanticVersion? from = first;
    final SemanticVersion? to = end;
    final bool aboveStart = from == null || version >= from;
    final bool belowEnd = to == null || version < to;
    return aboveStart && belowEnd;
  }

  /// Whether a bound, as the interval states it, is a pre-release of the
  /// same major, minor and patch as [version].
  ///
  /// Returns `true` when the interval names such a pre-release.
  @internal
  bool namesPreReleaseOf(SemanticVersion version) =>
      _isPreReleaseOfSameCore(lower, version) ||
      _isPreReleaseOfSameCore(upper, version);

  /// Whether [other] holds the same versions and names the same
  /// pre-releases.
  ///
  /// Returns `true` for an equal interval.
  @override
  bool operator ==(Object other) =>
      other is VersionInterval &&
      start == other.start &&
      startExclusive == other.startExclusive &&
      end == other.end;

  /// The hash code of the stored bounds.
  @override
  int get hashCode => Object.hash(start, startExclusive, end);

  /// Writes the interval in interval notation: `[1.2.0,2.0.0-0)`,
  /// `(,1.2.3]`, or `[1.4.0]` for exactly one version.
  ///
  /// Returns the canonical form.
  @override
  String toString() {
    final bool exact =
        lower != null && lower == upper && lowerInclusive && upperInclusive;
    if (exact) {
      return '$_inclusiveLower$lower$_inclusiveUpper';
    }
    final String opening = lowerInclusive ? _inclusiveLower : _exclusiveLower;
    final String closing = upperInclusive ? _inclusiveUpper : _exclusiveUpper;
    return '$opening${lower ?? ''}$_boundSeparator${upper ?? ''}$closing';
  }

  /// Whether [bound] is a pre-release of the same major, minor and patch as
  /// [version].
  ///
  /// Returns `true` for such a pre-release, `false` for no bound.
  static bool _isPreReleaseOfSameCore(
    SemanticVersion? bound,
    SemanticVersion version,
  ) {
    if (bound == null || !bound.isPreRelease) {
      return false;
    }
    final bool sameRelease =
        bound.major == version.major && bound.minor == version.minor;
    return sameRelease && bound.patch == version.patch;
  }
}
