/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/collection/iterable_extremes.dart';
import 'package:essentia/src/version/internal/interval_algebra.dart';
import 'package:essentia/src/version/internal/partial_grammar.dart';
import 'package:essentia/src/version/internal/range_grammar.dart';
import 'package:essentia/src/version/internal/range_reading.dart';
import 'package:essentia/src/version/internal/shorthands.dart';
import 'package:essentia/src/version/pre_release_policy.dart';
import 'package:essentia/src/version/semantic_version.dart';
import 'package:essentia/src/version/version_interval.dart';
import 'package:meta/meta.dart';

/// What separates the intervals of the canonical form.
const _intervalSeparator = ',';

/// How the range of no version at all renders.
const _nothing = '[]';

/// Why bounds with nothing between them are refused.
const _emptyRangeMessage =
    'A version range must not be empty: its lower bound is not below its '
    'upper';

/// A set of versions, such as "1.2 or later, but not 2" - read from the
/// notation npm and Cargo use, or from the interval notation Maven and OSGi
/// use.
///
/// ```dart
/// final supported = SemanticVersionRange.parse('^1.2 || ^2.0.0-rc.1');
///
/// supported.contains(SemanticVersion.parse('1.9.4')); // true
/// supported.maxSatisfying(published); // the newest one that fits
/// supported.intersect(SemanticVersionRange.parse('<2')); // what both allow
/// ```
///
/// ## What can be written
///
/// - `1.2.3`, `=1.2.3`: exactly 1.2.3.
/// - `>1.2.3`, `>=1.2`, `<2`, `<=1.4`: one side bounded; a shortened
///   version stands for its whole line.
/// - `1.2.x`, `1.2`, `1.x`, `*`: every version of that line, or every
///   version.
/// - `~1.2.3`: at least 1.2.3, within 1.2.
/// - `^1.2.3`: at least 1.2.3, within 1; within 0.2 for `^0.2.3`, only
///   0.0.3 for `^0.0.3`.
/// - `1.2 - 1.4`: at least 1.2.0, and every 1.4 version.
/// - `>=1.2.0 <2.0.0`: both at once.
/// - `[1.2, 2.0)`, `(,2.0]`, `[1.4.0]`: interval notation; a missing bound
///   is unbounded.
/// - `[1,2),[3,4)`, `^1 || ^3`: either.
///
/// Every shorthand means exactly what node-semver makes of it, including
/// the `-0` upper bounds that keep `2.0.0-rc.1` out of `^1.2.3`. A leading
/// `v` is refused, as it is for a version. A range that matches nothing -
/// `>2 <1`, `(1.0, 1.0)` - is refused rather than read as one that rejects
/// everything, and so is an alternative that does.
///
/// ## A set, not a spelling
///
/// A range is kept as disjoint, ascending [intervals], merged where they
/// meet. Two ranges holding the same versions are equal however they were
/// written, [toString] renders the one canonical interval form, and that
/// form reads back to an equal range: `^1.2.3` renders as
/// `[1.2.3,2.0.0-0)`. [none] is the one range that does not read back - it
/// renders as `[]`, and nothing written may match nothing.
///
/// ## Pre-releases
///
/// `range.contains(version)` is precedence, so `1.5.0-beta` is inside
/// `^1.2.0` - which is what makes [intersect] and [union] behave like the
/// set operations they are named after. Where a pre-release should only be
/// chosen when asked for, pass a [PreReleasePolicy]; [maxSatisfying] and
/// its siblings do so by default.
@immutable
final class SemanticVersionRange {
  /// Creates the range of [intervals], which are disjoint and ascending.
  SemanticVersionRange._(List<VersionInterval> intervals)
    : intervals = List<VersionInterval>.unmodifiable(intervals);

  /// The versions from [from], inclusive, up to [until], exclusive - or
  /// unbounded above when [until] is `null`. The shape a compatibility
  /// statement normally has.
  ///
  /// Throws an [ArgumentError] if [until] is not above [from].
  factory SemanticVersionRange.between(
    SemanticVersion from,
    SemanticVersion? until,
  ) => SemanticVersionRange.of(
    lower: from,
    lowerInclusive: true,
    upper: until,
    upperInclusive: false,
  );

  /// Exactly [version] - and every build of it, since precedence does not
  /// tell builds apart.
  factory SemanticVersionRange.exactly(SemanticVersion version) =>
      SemanticVersionRange.of(
        lower: version,
        lowerInclusive: true,
        upper: version,
        upperInclusive: true,
      );

  /// [version] and everything after it. Written `>=1.2.3` or `[1.2.3,)`.
  factory SemanticVersionRange.atLeast(SemanticVersion version) =>
      SemanticVersionRange.of(
        lower: version,
        lowerInclusive: true,
        upper: null,
        upperInclusive: false,
      );

  /// Everything before [version]. Written `<1.2.3` or `(,1.2.3)`.
  ///
  /// Throws an [ArgumentError] if [version] is `0.0.0-0`, the lowest
  /// version there is, so that nothing lies below it.
  factory SemanticVersionRange.below(SemanticVersion version) =>
      SemanticVersionRange.of(
        lower: null,
        lowerInclusive: false,
        upper: version,
        upperInclusive: false,
      );

  /// The versions a consumer of [version] can take without a change on
  /// their side, by the caret rule, written `^version`: `^1.2.3` is below
  /// `2.0.0`, `^0.2.3` below `0.3.0`, and `^0.0.3` is 0.0.3 alone, because a
  /// `0.` version promises nothing across a minor or, before `0.1`, a
  /// patch.
  factory SemanticVersionRange.caret(SemanticVersion version) =>
      SemanticVersionRange._(<VersionInterval>[
        ?caretInterval(partialOf(version)),
      ]);

  /// [version] and the patches after it, written `~version`: `~1.2.3` is
  /// at least 1.2.3 and below 1.3.0.
  factory SemanticVersionRange.tilde(SemanticVersion version) =>
      SemanticVersionRange._(<VersionInterval>[
        ?tildeInterval(partialOf(version)),
      ]);

  /// States a range of one interval, bound by bound.
  ///
  /// [lower] and [upper] are the bounds, `null` for none, and
  /// [lowerInclusive] and [upperInclusive] say whether each is in the
  /// range; they are ignored without a bound.
  ///
  /// Throws an [ArgumentError] if the bounds leave nothing between them:
  /// the lower above the upper, the two equal without both being inclusive,
  /// or no version between an exclusive pair such as `(1.2.3, 1.2.4-0)`.
  factory SemanticVersionRange.of({
    required SemanticVersion? lower,
    required bool lowerInclusive,
    required SemanticVersion? upper,
    required bool upperInclusive,
  }) {
    final VersionInterval? interval = bounded(
      lower: lower,
      lowerInclusive: lowerInclusive,
      upper: upper,
      upperInclusive: upperInclusive,
    );
    if (interval == null) {
      throw ArgumentError(_emptyRangeMessage);
    }
    return SemanticVersionRange._(<VersionInterval>[interval]);
  }

  /// Reads a range from [text], in either notation, with alternatives
  /// joined by `||`, such as `^1.2`, `>=1.2.0 <2.0.0` or `[1.2, 2.0)`.
  ///
  /// Throws a [FormatException] if [text] is not a range, or it or one of
  /// its alternatives matches no version. The message says what was wrong
  /// and does not quote [text].
  factory SemanticVersionRange.parse(String text) {
    final RangeReading reading = readRange(text);
    return switch (reading) {
      RangeRead() => SemanticVersionRange.fromReading(reading),
      RangeRefused(:final reason) => throw FormatException(_refusal(reason)),
    };
  }

  /// Creates the range [reading] read, whose intervals are already
  /// disjoint and ascending.
  @internal
  factory SemanticVersionRange.fromReading(RangeRead reading) =>
      SemanticVersionRange._(reading.intervals);

  /// Every version there is, for whatever has nothing to say about which.
  /// Written `*` or `(,)`.
  static final any = SemanticVersionRange._(<VersionInterval>[everything]);

  /// No version at all - what [intersect] answers for two constraints
  /// nothing satisfies.
  static final none = SemanticVersionRange._(const <VersionInterval>[]);

  /// The versions in this range, as disjoint intervals in ascending order.
  /// Empty for [none].
  final List<VersionInterval> intervals;

  /// Reads a range from [text], or answers `null` when [text] is not one.
  ///
  /// Returns the range, or `null` when [text] is not a range or matches no
  /// version.
  static SemanticVersionRange? tryParse(String text) {
    final RangeReading reading = readRange(text);
    return switch (reading) {
      RangeRead() => SemanticVersionRange.fromReading(reading),
      RangeRefused() => null,
    };
  }

  /// Whether no version at all is in this range. Only [intersect] produces
  /// such a range.
  bool get isEmpty => intervals.isEmpty;

  /// Whether every version is in this range.
  bool get isAny => intervals.length == 1 && intervals.single == everything;

  /// Whether [version] is in this range, with pre-releases admitted as
  /// [policy] says.
  ///
  /// Under the default [PreReleasePolicy.byPrecedence] this is plain
  /// membership. A release is placed by precedence under every policy.
  ///
  /// Returns `true` when [version] is inside.
  bool contains(
    SemanticVersion version, [
    PreReleasePolicy policy = PreReleasePolicy.byPrecedence,
  ]) {
    final VersionInterval? holder = intervals
        .where((interval) => interval.contains(version))
        .firstOrNull;
    if (holder == null) {
      return false;
    }
    if (!version.isPreRelease) {
      return true;
    }
    return switch (policy) {
      PreReleasePolicy.byPrecedence => true,
      PreReleasePolicy.sameCoreOnly => holder.namesPreReleaseOf(version),
      PreReleasePolicy.releasesOnly => false,
    };
  }

  /// The versions in both this range and [other].
  ///
  /// How two constraints on one dependency are combined: when the result
  /// [isEmpty], nothing can satisfy both.
  ///
  /// Returns the intersection, possibly [none].
  SemanticVersionRange intersect(SemanticVersionRange other) =>
      SemanticVersionRange._(intersection(intervals, other.intervals));

  /// The versions in this range, in [other], or in both.
  ///
  /// Returns the union, with touching intervals merged.
  SemanticVersionRange union(SemanticVersionRange other) =>
      SemanticVersionRange._(
        normalized(<VersionInterval>[...intervals, ...other.intervals]),
      );

  /// The newest of [versions] that is in this range.
  ///
  /// Versions that differ only in build metadata are told apart by
  /// [SemanticVersion.totalOrder], so the answer does not depend on the
  /// order [versions] come in. [policy] says when a pre-release may be
  /// chosen: [PreReleasePolicy.sameCoreOnly] unless said otherwise, because
  /// selecting is what a resolver does, and a resolver should not hand out
  /// a pre-release nobody asked for.
  ///
  /// Returns the newest version inside, or `null` when none is.
  SemanticVersion? maxSatisfying(
    Iterable<SemanticVersion> versions, [
    PreReleasePolicy policy = PreReleasePolicy.sameCoreOnly,
  ]) => satisfying(versions, policy).maxWithOrNull(SemanticVersion.totalOrder);

  /// The oldest of [versions] that is in this range - the one a build
  /// testing its lower bound wants.
  ///
  /// [policy] says when a pre-release may be chosen:
  /// [PreReleasePolicy.sameCoreOnly] unless said otherwise.
  ///
  /// Returns the oldest version inside, or `null` when none is.
  SemanticVersion? minSatisfying(
    Iterable<SemanticVersion> versions, [
    PreReleasePolicy policy = PreReleasePolicy.sameCoreOnly,
  ]) => satisfying(versions, policy).minWithOrNull(SemanticVersion.totalOrder);

  /// Those of [versions] that are in this range, in the order they were
  /// given.
  ///
  /// [policy] says when a pre-release is kept:
  /// [PreReleasePolicy.sameCoreOnly] unless said otherwise.
  ///
  /// Returns the versions inside, as an unmodifiable list.
  List<SemanticVersion> satisfying(
    Iterable<SemanticVersion> versions, [
    PreReleasePolicy policy = PreReleasePolicy.sameCoreOnly,
  ]) => List<SemanticVersion>.unmodifiable(
    versions.where((version) => contains(version, policy)),
  );

  /// Whether [other] holds the same versions and names the same
  /// pre-releases, however either was written.
  ///
  /// Returns `true` for an equal range.
  @override
  bool operator ==(Object other) {
    if (other is! SemanticVersionRange ||
        intervals.length != other.intervals.length) {
      return false;
    }
    for (var index = 0; index < intervals.length; index++) {
      if (intervals[index] != other.intervals[index]) {
        return false;
      }
    }
    return true;
  }

  /// The hash code of the intervals.
  @override
  int get hashCode => Object.hashAll(intervals);

  /// Writes the range in its canonical interval form:
  /// `[1.2.0,2.0.0-0),[3.0.0,4.0.0-0)`, `(,)` for [any] and `[]` for
  /// [none].
  ///
  /// Returns the canonical form, which reads back to an equal range for
  /// every range but [none].
  @override
  String toString() {
    if (intervals.isEmpty) {
      return _nothing;
    }
    return intervals.join(_intervalSeparator);
  }

  /// The message of a text that is not a range, refused for [reason].
  ///
  /// Returns the message.
  static String _refusal(String reason) => 'Not a version range: it $reason';
}
