/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/version/internal/identifier_rules.dart';
import 'package:essentia_core/src/version/internal/version_grammar.dart';
import 'package:essentia_core/src/version/internal/version_reading.dart';
import 'package:essentia_core/src/version/internal/version_steps.dart';
import 'package:essentia_core/src/version/pre_release_policy.dart';
import 'package:essentia_core/src/version/semantic_version_range.dart';
import 'package:meta/meta.dart';

/// The first number of a new pre-release line.
const _firstPreRelease = '1';

/// What a number that cannot be raised any further says.
const _exhausted = 'cannot be raised past $maxNumber';

/// Why a release has no next pre-release.
const _noLineMessage =
    'A release has no pre-release line to continue: name one with '
    'nextPreRelease(label)';

/// A version, as specified by Semantic Versioning 2.0.0.
///
/// Three numbers, an optional pre-release and optional build metadata:
/// `1.4.0`, `2.0.0-rc.1`, `1.4.0+sha.9f3c`. Every project that has to say
/// "this component is 1.4.0" or "this works from 1.2 up to 2.0" otherwise
/// writes its own parser, and the one in each project disagrees with the
/// next about pre-release ordering. This is the one they share.
///
/// ```dart
/// final shell = SemanticVersion.parse('1.4.0');
/// final candidate = SemanticVersion.parse('2.0.0-rc.1');
///
/// candidate < SemanticVersion.of(2); // true - a pre-release precedes its release
/// ```
///
/// ## Ordering is precedence, equality is identity
///
/// [compareTo] implements the specification's precedence: the three
/// numbers, then the pre-release - a version with one sorts **below** the
/// same version without - identifier by identifier, numeric identifiers
/// numerically and below alphanumeric ones. Build metadata is not part of
/// precedence.
///
/// [operator ==] compares everything, build metadata included, because
/// `1.0.0+a` and `1.0.0+b` are two different artefacts. The natural
/// ordering is therefore deliberately inconsistent with equality: the two
/// compare as equal and are not equal. Both halves are what a reader
/// expects, and a sorted set keyed by precedence will keep only one of
/// them.
///
/// [precedence] is that ordering as a [Comparator]. [totalOrder] breaks the
/// remaining ties by build metadata, so it agrees with equality and is the
/// one to key a sorted set or map by.
///
/// ## Strict on the way in
///
/// What the specification refuses is refused: a leading `v`, a leading
/// zero in a number or a numeric pre-release identifier, an empty
/// identifier, surrounding whitespace, a number beyond 2147483647, the
/// largest 32-bit integer. Trim at the boundary where text
/// arrives from somewhere loose.
///
/// ## The next version
///
/// [nextMajor], [nextMinor] and [nextPatch] follow the increments release
/// tooling uses: a pre-release is released by the step it was a
/// pre-release of, so `2.0.0-rc.2` is followed by `2.0.0` under [nextMajor]
/// rather than by `3.0.0`. [nextPreRelease] continues or starts a
/// pre-release line. Each drops build metadata, because a new version is a
/// new build.
@immutable
final class SemanticVersion implements Comparable<SemanticVersion> {
  /// Creates the version from parts already checked and frozen.
  const SemanticVersion._(
    this.major,
    this.minor,
    this.patch,
    this.preRelease,
    this.build,
  );

  /// States a version of [major], [minor] and [patch], with the
  /// [preRelease] identifiers, empty for a release, and the [build]
  /// metadata identifiers, empty when there are none.
  ///
  /// The version keeps copies of the lists, so changing them afterwards
  /// changes nothing.
  ///
  /// Throws an [ArgumentError] if a number is negative or larger than
  /// 2147483647, or an identifier is empty, holds a character outside
  /// `[0-9A-Za-z-]`, or is a numeric pre-release identifier with a leading
  /// zero.
  factory SemanticVersion.of(
    int major, {
    int minor = 0,
    int patch = 0,
    List<String> preRelease = const <String>[],
    List<String> build = const <String>[],
  }) {
    if (major < 0 || minor < 0 || patch < 0) {
      throw ArgumentError('A version number must not be negative');
    }
    if (major > maxNumber || minor > maxNumber || patch > maxNumber) {
      throw ArgumentError(
        'A version number must not be larger than $maxNumber',
      );
    }
    final String? preReleaseIssue = preReleaseProblem(preRelease);
    if (preReleaseIssue != null) {
      throw ArgumentError('A version $preReleaseIssue');
    }
    final String? buildIssue = buildProblem(build);
    if (buildIssue != null) {
      throw ArgumentError('A version $buildIssue');
    }
    return SemanticVersion._(
      major,
      minor,
      patch,
      List<String>.unmodifiable(preRelease),
      List<String>.unmodifiable(build),
    );
  }

  /// Reads a version from [text], such as `1.4.0` or `2.0.0-rc.1+sha.9f3c`.
  ///
  /// Throws a [FormatException] if [text] is not a semantic version. The
  /// message says what was wrong and does not quote [text].
  factory SemanticVersion.parse(String text) {
    final VersionReading reading = readVersion(text);
    return switch (reading) {
      VersionRead() => SemanticVersion.fromReading(reading),
      VersionRefused(:final reason) => throw FormatException(_refusal(reason)),
    };
  }

  /// Creates the version [reading] read, which needs no further check.
  @internal
  factory SemanticVersion.fromReading(VersionRead reading) => SemanticVersion._(
    reading.major,
    reading.minor,
    reading.patch,
    List<String>.unmodifiable(reading.preRelease),
    List<String>.unmodifiable(reading.build),
  );

  /// Orders versions by the specification's precedence - the natural
  /// ordering. Versions that differ only in build metadata compare as
  /// equal. A [Comparator] of versions, to sort [left] and [right] by.
  ///
  /// Returns a negative number, zero or a positive number when [left] comes
  /// before, with or after [right].
  static int precedence(SemanticVersion left, SemanticVersion right) =>
      left.compareTo(right);

  /// Orders versions by precedence, then by build metadata: none first,
  /// then identifier by identifier, numeric ones numerically and below
  /// alphanumeric ones.
  ///
  /// Two versions compare as equal under this ordering exactly when they
  /// are equal, so a sorted set or map keyed by it keeps `1.0.0+a` and
  /// `1.0.0+b` apart where one keyed by [precedence] keeps only the first.
  /// A [Comparator] of versions, to sort [left] and [right] by.
  ///
  /// Returns a negative number, zero or a positive number when [left] comes
  /// before, with or after [right].
  static int totalOrder(SemanticVersion left, SemanticVersion right) {
    final int byPrecedence = left.compareTo(right);
    if (byPrecedence != 0) {
      return byPrecedence;
    }
    return compareBuilds(left.build, right.build);
  }

  /// The major version, raised when something a consumer relies on is
  /// taken away.
  final int major;

  /// The minor version, raised when something is added.
  final int minor;

  /// The patch version, raised when something is fixed.
  final int patch;

  /// The dot-separated pre-release identifiers, empty for a release.
  final List<String> preRelease;

  /// The dot-separated build metadata identifiers, empty when nothing was
  /// said.
  final List<String> build;

  /// Reads a version from [text], or answers `null` when [text] is not one.
  ///
  /// The form for a validation, which has other mistakes to report beside
  /// this one - see `VersionValidations.semanticVersion` for the helper
  /// that reports it as a violation.
  ///
  /// Returns the version, or `null` when [text] is not a semantic version.
  static SemanticVersion? tryParse(String text) {
    final VersionReading reading = readVersion(text);
    return switch (reading) {
      VersionRead() => SemanticVersion.fromReading(reading),
      VersionRefused() => null,
    };
  }

  /// Whether this is a pre-release rather than the release itself.
  bool get isPreRelease => preRelease.isNotEmpty;

  /// Whether this version makes the promises Semantic Versioning describes:
  /// a release, and past the initial development of `0.y.z`, where anything
  /// may change at any time.
  bool get isStable => major > 0 && !isPreRelease;

  /// The next major version: `1.4.2` becomes `2.0.0`, and a pre-release of
  /// a major version, such as `2.0.0-rc.1`, becomes that release.
  ///
  /// Returns the next major version, without build metadata.
  ///
  /// Throws a [StateError] if the major version is already 2147483647.
  SemanticVersion nextMajor() {
    if (isPreRelease && minor == 0 && patch == 0) {
      return SemanticVersion.of(major);
    }
    if (major >= maxNumber) {
      throw StateError('A major version $_exhausted');
    }
    return SemanticVersion.of(major + 1);
  }

  /// The next minor version: `1.4.2` becomes `1.5.0`, and a pre-release of
  /// a minor version, such as `1.5.0-beta`, becomes that release.
  ///
  /// Returns the next minor version, without build metadata.
  ///
  /// Throws a [StateError] if the minor version is already 2147483647.
  SemanticVersion nextMinor() {
    if (isPreRelease && patch == 0) {
      return SemanticVersion.of(major, minor: minor);
    }
    if (minor >= maxNumber) {
      throw StateError('A minor version $_exhausted');
    }
    return SemanticVersion.of(major, minor: minor + 1);
  }

  /// The next patch version: `1.4.2` becomes `1.4.3`, and any pre-release
  /// becomes its release.
  ///
  /// Returns the next patch version, without build metadata.
  ///
  /// Throws a [StateError] if the patch version is already 2147483647.
  SemanticVersion nextPatch() {
    if (isPreRelease) {
      return release();
    }
    if (patch >= maxNumber) {
      throw StateError('A patch version $_exhausted');
    }
    return SemanticVersion.of(major, minor: minor, patch: patch + 1);
  }

  /// The next pre-release, on this version's line or on the one labelled
  /// [label].
  ///
  /// Without a [label], the last numeric identifier of this version's line
  /// goes up by one - `rc.1` to `rc.2`, `beta.9` to `beta.10` - and a line
  /// without one gains `.1`.
  ///
  /// On a line already labelled [label], it is the same. A pre-release
  /// with another label moves to `label.1` of the same version -
  /// `1.0.0-beta.3` to `1.0.0-rc.1`. A release starts `label.1` on the next
  /// patch - `1.2.3` to `1.2.4-rc.1`; for a pre-release of the next minor or
  /// major, raise that first: `nextMajor().withPreRelease(['rc', '1'])`.
  ///
  /// [label] is the first pre-release identifier, such as `alpha`, `beta`
  /// or `rc`.
  ///
  /// Returns the next pre-release, without build metadata.
  ///
  /// Throws an [ArgumentError] if [label] is not a pre-release identifier,
  /// or moving to it would go backwards - `1.0.0-rc.1` to `1.0.0-alpha.1`.
  /// Throws a [StateError] if this is a release and no [label] is given,
  /// since a release has no line to continue, or if this is a release
  /// whose patch version is already 2147483647.
  SemanticVersion nextPreRelease([String? label]) {
    if (label == null) {
      return _continuedLine();
    }
    if (!isPreReleaseIdentifier(label)) {
      throw ArgumentError.value(
        label,
        'label',
        'A pre-release label must be a pre-release identifier',
      );
    }
    if (preRelease.firstOrNull == label) {
      return _continuedLine();
    }
    if (!isPreRelease) {
      if (patch >= maxNumber) {
        throw StateError('A patch version $_exhausted');
      }
      return SemanticVersion.of(
        major,
        minor: minor,
        patch: patch + 1,
        preRelease: <String>[label, _firstPreRelease],
      );
    }
    final started = SemanticVersion.of(
      major,
      minor: minor,
      patch: patch,
      preRelease: <String>[label, _firstPreRelease],
    );
    if (started <= this) {
      throw ArgumentError.value(
        label,
        'label',
        'A pre-release label must not move a version backwards',
      );
    }
    return started;
  }

  /// The release this version is, or is a pre-release of:
  /// `2.0.0-rc.1+sha.9f3c` becomes `2.0.0`.
  ///
  /// Returns the version without pre-release and build metadata, this one
  /// when it has neither.
  SemanticVersion release() {
    if (!isPreRelease && build.isEmpty) {
      return this;
    }
    return SemanticVersion.of(major, minor: minor, patch: patch);
  }

  /// This version without its build metadata - the part precedence
  /// considers.
  ///
  /// Returns the version without build metadata, or this one when it has
  /// none.
  SemanticVersion withoutBuild() {
    if (build.isEmpty) {
      return this;
    }
    return SemanticVersion._(major, minor, patch, preRelease, const <String>[]);
  }

  /// This version with its pre-release replaced by [identifiers], keeping
  /// the build metadata; none makes it a release.
  ///
  /// Returns the version.
  ///
  /// Throws an [ArgumentError] if an identifier is not a pre-release
  /// identifier.
  SemanticVersion withPreRelease([
    List<String> identifiers = const <String>[],
  ]) => SemanticVersion.of(
    major,
    minor: minor,
    patch: patch,
    preRelease: identifiers,
    build: build,
  );

  /// This version with its build metadata replaced by [identifiers],
  /// keeping the pre-release; none removes the build metadata.
  ///
  /// Returns the version.
  ///
  /// Throws an [ArgumentError] if an identifier is not a build identifier.
  SemanticVersion withBuild([List<String> identifiers = const <String>[]]) =>
      SemanticVersion.of(
        major,
        minor: minor,
        patch: patch,
        preRelease: preRelease,
        build: identifiers,
      );

  /// Whether this version can stand in where [baseline] was depended on, by
  /// the caret rule.
  ///
  /// `1.9.0` can stand in for `1.2.0`, not the other way round, and not
  /// `2.0.0`. Below `1.0.0` the rule narrows as the specification's initial
  /// development does: `0.2.5` stands in for `0.2.3` and `0.3.0` does not,
  /// and a `0.0.z` stands in only for itself. A pre-release stands in only
  /// for a pre-release of the same version, because it promises nothing -
  /// see [PreReleasePolicy.sameCoreOnly].
  ///
  /// Returns `true` when this version is in [SemanticVersionRange.caret] of
  /// [baseline].
  bool isCompatibleWith(SemanticVersion baseline) =>
      SemanticVersionRange.caret(baseline)
          .contains(this, PreReleasePolicy.sameCoreOnly);

  /// Compares this version with [other] by the specification's precedence.
  ///
  /// Returns a negative number, zero or a positive number when this version
  /// comes before, with or after [other].
  @override
  int compareTo(SemanticVersion other) {
    final int byMajor = major.compareTo(other.major);
    if (byMajor != 0) {
      return byMajor;
    }
    final int byMinor = minor.compareTo(other.minor);
    if (byMinor != 0) {
      return byMinor;
    }
    final int byPatch = patch.compareTo(other.patch);
    if (byPatch != 0) {
      return byPatch;
    }
    return comparePreReleases(preRelease, other.preRelease);
  }

  /// Whether this version precedes [other].
  ///
  /// Returns `true` when it comes first by precedence.
  bool operator <(SemanticVersion other) => compareTo(other) < 0;

  /// Whether this version precedes [other] or shares its precedence.
  ///
  /// Returns `true` when it does not come after [other].
  bool operator <=(SemanticVersion other) => compareTo(other) <= 0;

  /// Whether this version follows [other].
  ///
  /// Returns `true` when it comes after [other] by precedence.
  bool operator >(SemanticVersion other) => compareTo(other) > 0;

  /// Whether this version follows [other] or shares its precedence.
  ///
  /// Returns `true` when it does not come before [other].
  bool operator >=(SemanticVersion other) => compareTo(other) >= 0;

  /// Whether [other] is the same version, build metadata included.
  ///
  /// Returns `true` for an equal version.
  @override
  bool operator ==(Object other) =>
      other is SemanticVersion &&
      major == other.major &&
      minor == other.minor &&
      patch == other.patch &&
      _sameIdentifiers(preRelease, other.preRelease) &&
      _sameIdentifiers(build, other.build);

  /// The hash code of every part, build metadata included.
  @override
  int get hashCode => Object.hash(
    major,
    minor,
    patch,
    Object.hashAll(preRelease),
    Object.hashAll(build),
  );

  /// Writes the version down as the specification does:
  /// `2.0.0-rc.1+sha.9f3c`.
  ///
  /// Returns the text form, which reads back to an equal version.
  @override
  String toString() {
    final String released = _qualified(
      '$major.$minor.$patch',
      preReleaseSeparator,
      preRelease,
    );
    return _qualified(released, buildSeparator, build);
  }

  /// The next pre-release on this version's line.
  ///
  /// Returns that pre-release.
  ///
  /// Throws a [StateError] if this is a release.
  SemanticVersion _continuedLine() {
    if (!isPreRelease) {
      throw StateError(_noLineMessage);
    }
    return SemanticVersion.of(
      major,
      minor: minor,
      patch: patch,
      preRelease: _continued(preRelease),
    );
  }

  /// The pre-release line [identifiers] continued: its last numeric
  /// identifier raised, or `1` appended when it has none.
  ///
  /// Returns the continued identifiers.
  static List<String> _continued(List<String> identifiers) {
    final int position = identifiers.lastIndexWhere(isNumeral);
    if (position < 0) {
      return <String>[...identifiers, _firstPreRelease];
    }
    return <String>[...identifiers]
      ..[position] = incremented(identifiers[position]);
  }

  /// [text] followed by [separator] and [identifiers], or [text] alone
  /// when there are none.
  ///
  /// Returns the qualified text.
  static String _qualified(
    String text,
    String separator,
    List<String> identifiers,
  ) {
    if (identifiers.isEmpty) {
      return text;
    }
    return text + separator + identifiers.join(identifierSeparator);
  }

  /// Whether [left] and [right] hold the same identifiers in the same
  /// order.
  ///
  /// Returns `true` for equal lists.
  static bool _sameIdentifiers(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  /// The message of a text that is not a version, refused for [reason].
  ///
  /// Returns the message.
  static String _refusal(String reason) => 'Not a semantic version: it $reason';
}
