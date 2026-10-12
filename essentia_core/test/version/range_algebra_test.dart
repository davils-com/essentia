/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/version/pre_release_policy.dart';
import 'package:essentia_core/src/version/semantic_version.dart';
import 'package:essentia_core/src/version/semantic_version_range.dart';
import 'package:test/test.dart';

/// Reads [text] as a version.
///
/// Returns the version.
SemanticVersion _version(String text) => SemanticVersion.parse(text);

/// Reads [text] as a range.
///
/// Returns the range.
SemanticVersionRange _range(String text) => SemanticVersionRange.parse(text);

/// Reads every one of [texts] as a version.
///
/// Returns the versions, in order.
List<SemanticVersion> _versions(List<String> texts) =>
    texts.map(_version).toList();

/// Tests intersecting, uniting, the pre-release policies and selecting.
void main() {
  group('intersecting', () {
    test('keeps what both ranges allow', () {
      expect(_range('^1.2').intersect(_range('<1.5')), _range('>=1.2.0 <1.5'));
    });

    test('of two ranges nothing satisfies is empty', () {
      final SemanticVersionRange both = _range('^1').intersect(_range('^2'));

      expect(both.isEmpty, isTrue);
      expect(both, SemanticVersionRange.none);
    });

    test('with any changes nothing', () {
      expect(
        _range('^1.2 || ^3').intersect(SemanticVersionRange.any),
        _range('^1.2 || ^3'),
      );
    });

    test('cuts every interval of a union', () {
      final SemanticVersionRange cut = _range('^1 || ^3')
          .intersect(_range('>=1.5 <3.5'));

      expect(cut, _range('>=1.5.0 <2.0.0-0 || >=3.0.0 <3.5'));
    });
  });

  group('uniting', () {
    test('merges intervals that overlap', () {
      expect(_range('^1.2').union(_range('~1.9 || <1.3')), _range('<2.0.0-0'));
    });

    test('merges intervals that only touch', () {
      expect(_range('[1,2)').union(_range('[2,3)')), _range('[1,3)'));
    });

    test('keeps intervals with versions between them apart', () {
      final SemanticVersionRange united = _range('^1').union(_range('^2'));

      expect(united.intervals, hasLength(2));
      expect(united.contains(_version('2.0.0-rc.1')), isFalse);
    });

    test('with none changes nothing', () {
      expect(_range('^1.2').union(SemanticVersionRange.none), _range('^1.2'));
    });
  });

  group('pre-release policies', () {
    test('by precedence, a pre-release is wherever its precedence puts '
        'it', () {
      expect(_range('^1.2.0').contains(_version('1.5.0-beta')), isTrue);
    });

    test('same core only admits a pre-release a bound names, as npm '
        'does', () {
      final SemanticVersionRange range = _range('>1.2.3-alpha.3');

      expect(
        range.contains(
          _version('1.2.3-alpha.7'),
          PreReleasePolicy.sameCoreOnly,
        ),
        isTrue,
      );
      expect(
        range.contains(
          _version('3.4.5-alpha.9'),
          PreReleasePolicy.sameCoreOnly,
        ),
        isFalse,
      );
      expect(
        range.contains(_version('3.4.5'), PreReleasePolicy.sameCoreOnly),
        isTrue,
      );
    });

    test('same core only is decided by the interval that holds the '
        'version', () {
      final SemanticVersionRange range = _range(
        '>=1.0.0-rc.1 <1.1 || >=2.0.0 <3',
      );

      expect(
        range.contains(_version('1.0.0-rc.2'), PreReleasePolicy.sameCoreOnly),
        isTrue,
      );
      expect(
        range.contains(_version('2.1.0-rc.2'), PreReleasePolicy.sameCoreOnly),
        isFalse,
      );
    });

    test('an upper bound names a pre-release as well', () {
      expect(
        _range('<1.2.3-rc.1')
            .contains(_version('1.2.3-beta'), PreReleasePolicy.sameCoreOnly),
        isTrue,
      );
    });

    test('the -0 floor a shorthand adds admits nothing', () {
      expect(
        _range('^1.2.3')
            .contains(_version('2.0.0-rc.1'), PreReleasePolicy.sameCoreOnly),
        isFalse,
      );
    });

    test('releases only never admits a pre-release', () {
      expect(
        _range('>=1.2.3-rc.1')
            .contains(_version('1.2.3-rc.2'), PreReleasePolicy.releasesOnly),
        isFalse,
      );
    });

    test('a release is placed by precedence under every policy', () {
      for (final PreReleasePolicy policy in PreReleasePolicy.values) {
        expect(_range('^1.2').contains(_version('1.4.0'), policy), isTrue);
        expect(_range('^1.2').contains(_version('2.0.0'), policy), isFalse);
      }
    });
  });

  group('selecting', () {
    final List<SemanticVersion> published = _versions(<String>[
      '1.2.3',
      '1.2.4',
      '1.3.0-beta',
      '2.0.0',
      '1.1.0',
    ]);

    test('the newest version inside, without a pre-release nobody asked '
        'for', () {
      expect(_range('^1.2').maxSatisfying(published), _version('1.2.4'));
    });

    test('the newest version inside by precedence, when asked', () {
      expect(
        _range('^1.2').maxSatisfying(published, PreReleasePolicy.byPrecedence),
        _version('1.3.0-beta'),
      );
    });

    test('the oldest version inside', () {
      expect(_range('^1.2').minSatisfying(published), _version('1.2.3'));
    });

    test('nothing when no version fits', () {
      expect(_range('^3').maxSatisfying(published), isNull);
      expect(_range('^3').minSatisfying(published), isNull);
    });

    test('every version inside, in the order given', () {
      expect(
        _range('^1').satisfying(published),
        _versions(<String>['1.2.3', '1.2.4', '1.1.0']),
      );
    });

    test('the same answer among builds of one version, whatever order they '
        'come in', () {
      final List<SemanticVersion> builds = _versions(<String>[
        '1.2.4+b',
        '1.2.4+a',
        '1.2.4+c',
      ]);

      expect(_range('^1').maxSatisfying(builds), _version('1.2.4+c'));
      expect(_range('^1').maxSatisfying(builds.reversed), _version('1.2.4+c'));
      expect(_range('^1').minSatisfying(builds), _version('1.2.4+a'));
    });
  });
}
