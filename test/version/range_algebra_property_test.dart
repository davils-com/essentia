/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

import 'package:essentia/src/version/internal/interval_algebra.dart';
import 'package:essentia/src/version/pre_release_policy.dart';
import 'package:essentia/src/version/semantic_version.dart';
import 'package:essentia/src/version/semantic_version_range.dart';
import 'package:test/test.dart';

/// How many cases each property is checked against.
const _cases = 500;

/// The identifiers a pre-release is drawn from.
const _preReleases = <String>['alpha', 'rc', '0', '1', '2'];

/// The identifiers a build is drawn from.
const _builds = <String>['a', 'b', '7'];

/// How often a bound is left out: one time in five.
const _missingBound = 5;

/// Draws up to [most] identifiers of [options] from [random].
///
/// Returns the identifiers.
List<String> _randomIdentifiers(
  Random random,
  List<String> options,
  int most,
) => <String>[
  for (var count = random.nextInt(most + 1); count > 0; count--)
    options[random.nextInt(options.length)],
];

/// Draws a version with small numbers, up to two pre-release identifiers
/// and up to one build identifier from [random].
///
/// Returns the version.
SemanticVersion _randomVersion(Random random) => SemanticVersion.of(
  random.nextInt(4),
  minor: random.nextInt(4),
  patch: random.nextInt(4),
  preRelease: _randomIdentifiers(random, _preReleases, 2),
  build: _randomIdentifiers(random, _builds, 1),
);

/// Draws a bound from [random], left out one time in five.
///
/// Returns the bound, or `null` for none.
SemanticVersion? _randomBound(Random random) =>
    random.nextInt(_missingBound) == 0 ? null : _randomVersion(random);

/// Draws a range of one interval from [random]; bounds with nothing between
/// them make it exactly one of them instead.
///
/// Returns the range.
SemanticVersionRange _randomSingleInterval(Random random) {
  final SemanticVersion? lower = _randomBound(random);
  final bool lowerInclusive = random.nextBool();
  final SemanticVersion? upper = _randomBound(random);
  final bool upperInclusive = random.nextBool();
  final empty =
      bounded(
        lower: lower,
        lowerInclusive: lowerInclusive,
        upper: upper,
        upperInclusive: upperInclusive,
      ) ==
      null;
  if (empty) {
    return SemanticVersionRange.exactly(
      lower ?? upper ?? SemanticVersion.of(1),
    );
  }
  return SemanticVersionRange.of(
    lower: lower,
    lowerInclusive: lowerInclusive,
    upper: upper,
    upperInclusive: upperInclusive,
  );
}

/// Draws the union of one to three single intervals from [random].
///
/// Returns the range.
SemanticVersionRange _randomRange(Random random) => <SemanticVersionRange>[
  for (var count = random.nextInt(3) + 1; count > 0; count--)
    _randomSingleInterval(random),
].reduce((left, right) => left.union(right));

/// Draws up to eight versions from [random].
///
/// Returns the versions.
List<SemanticVersion> _randomVersions(Random random) => <SemanticVersion>[
  for (var count = random.nextInt(9); count > 0; count--)
    _randomVersion(random),
];

/// Runs [check] [_cases] times with a [Random] seeded with [seed].
void _forAll(int seed, void Function(Random random) check) {
  final random = Random(seed);
  for (var round = 0; round < _cases; round++) {
    check(random);
  }
}

/// Tests the properties of the range algebra, against randomly drawn
/// ranges and versions.
void main() {
  group('the set operations', () {
    test('a version is in a union exactly when it is in either side', () {
      _forAll(31, (random) {
        final SemanticVersionRange left = _randomRange(random);
        final SemanticVersionRange right = _randomRange(random);
        final SemanticVersion version = _randomVersion(random);

        expect(
          left.union(right).contains(version),
          left.contains(version) || right.contains(version),
        );
      });
    });

    test('a version is in an intersection exactly when it is in both '
        'sides', () {
      _forAll(32, (random) {
        final SemanticVersionRange left = _randomRange(random);
        final SemanticVersionRange right = _randomRange(random);
        final SemanticVersion version = _randomVersion(random);

        expect(
          left.intersect(right).contains(version),
          left.contains(version) && right.contains(version),
        );
      });
    });

    test('both are commutative', () {
      _forAll(33, (random) {
        final SemanticVersionRange left = _randomRange(random);
        final SemanticVersionRange right = _randomRange(random);

        expect(left.union(right), right.union(left));
        expect(left.intersect(right), right.intersect(left));
      });
    });

    test('both are idempotent', () {
      _forAll(34, (random) {
        final SemanticVersionRange range = _randomRange(random);

        expect(range.union(range), range);
        expect(range.intersect(range), range);
      });
    });
  });

  group('the canonical form', () {
    test('reads back to an equal range', () {
      _forAll(35, (random) {
        final SemanticVersionRange range = _randomRange(random);

        expect(
          SemanticVersionRange.parse(range.toString()),
          range,
          reason: range.toString(),
        );
      });
    });

    test('keeps intervals disjoint, ascending and apart', () {
      _forAll(36, (random) {
        final SemanticVersionRange range = _randomRange(random);
        for (var index = 1; index < range.intervals.length; index++) {
          final SemanticVersion? end = range.intervals[index - 1].end;
          final SemanticVersion? start = range.intervals[index].first;

          expect(
            end != null && start != null && end < start,
            isTrue,
            reason: range.toString(),
          );
        }
      });
    });
  });

  group('the discrete bounds', () {
    test('an exclusive lower bound admits exactly the versions above it', () {
      _forAll(37, (random) {
        final SemanticVersion bound = _randomVersion(random);
        final SemanticVersion version = _randomVersion(random);

        expect(
          SemanticVersionRange.parse('>$bound').contains(version),
          version > bound,
        );
      });
    });

    test('an inclusive upper bound admits exactly the versions up to it', () {
      _forAll(38, (random) {
        final SemanticVersion bound = _randomVersion(random);
        final SemanticVersion version = _randomVersion(random);

        expect(
          SemanticVersionRange.parse('<=$bound').contains(version),
          version <= bound,
        );
      });
    });

    test('exactly one version admits only that version, whatever its '
        'build', () {
      _forAll(39, (random) {
        final SemanticVersion bound = _randomVersion(random);
        final SemanticVersion version = _randomVersion(random);

        expect(
          SemanticVersionRange.exactly(bound).contains(version),
          version.compareTo(bound) == 0,
        );
      });
    });
  });

  group('pre-release policies', () {
    test('by precedence is plain membership', () {
      _forAll(40, (random) {
        final SemanticVersionRange range = _randomRange(random);
        final SemanticVersion version = _randomVersion(random);

        expect(range.contains(version), range.contains(version));
      });
    });

    test('the stricter policies only ever take versions away', () {
      _forAll(41, (random) {
        final SemanticVersionRange range = _randomRange(random);
        final SemanticVersion version = _randomVersion(random);
        final bool sameCore = range.contains(
          version,
          PreReleasePolicy.sameCoreOnly,
        );
        final bool releasesOnly = range.contains(
          version,
          PreReleasePolicy.releasesOnly,
        );

        expect(!sameCore || range.contains(version), isTrue);
        expect(!releasesOnly || sameCore, isTrue);
        expect(releasesOnly && version.isPreRelease, isFalse);
      });
    });
  });

  group('selecting', () {
    test('the newest version chosen is inside, and nothing inside is '
        'newer', () {
      _forAll(42, (random) {
        final SemanticVersionRange range = _randomRange(random);
        final List<SemanticVersion> candidates = _randomVersions(random);
        final SemanticVersion? chosen = range.maxSatisfying(candidates);
        final List<SemanticVersion> inside = range.satisfying(candidates);

        expect(chosen == null, inside.isEmpty);
        final Iterable<SemanticVersion> newer = inside.where(
          (version) =>
              chosen != null && SemanticVersion.totalOrder(version, chosen) > 0,
        );
        expect(newer, isEmpty);
      });
    });
  });

  group('the operations on a version', () {
    test('every next version is above the one it follows', () {
      _forAll(43, (random) {
        final SemanticVersion version = _randomVersion(random);

        expect(version.nextMajor() > version, isTrue);
        expect(version.nextMinor() > version, isTrue);
        expect(version.nextPatch() > version, isTrue);
        expect(version.nextPreRelease('zeta') > version, isTrue);
      });
    });

    test('a version is compatible with itself', () {
      _forAll(44, (random) {
        final SemanticVersion version = _randomVersion(random);

        expect(version.isCompatibleWith(version), isTrue);
      });
    });

    test('the total order agrees with equality', () {
      _forAll(45, (random) {
        final SemanticVersion left = _randomVersion(random);
        final SemanticVersion right = _randomVersion(random);

        expect(SemanticVersion.totalOrder(left, right) == 0, left == right);
      });
    });
  });
}
