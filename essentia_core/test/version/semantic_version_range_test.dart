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
import 'package:essentia_core/src/version/version_interval.dart';
import 'package:test/test.dart';

/// Reads [text] as a version.
///
/// Returns the version.
SemanticVersion _version(String text) => SemanticVersion.parse(text);

/// Reads [text] as a range.
///
/// Returns the range.
SemanticVersionRange _range(String text) => SemanticVersionRange.parse(text);

/// Tests the interval notation, what is refused, stating a range and when
/// two ranges are equal.
void main() {
  group('the interval form', () {
    test('closed below and open above holds its lower bound and not its '
        'upper', () {
      final SemanticVersionRange range = _range('[1.2, 2.0)');

      expect(range.contains(_version('1.2.0')), isTrue);
      expect(range.contains(_version('1.9.3')), isTrue);
      expect(range.contains(_version('2.0.0')), isFalse);
      expect(range.contains(_version('1.1.9')), isFalse);
    });

    test('open below and closed above holds its upper bound and not its '
        'lower', () {
      final SemanticVersionRange range = _range('(1.0,2.0]');

      expect(range.contains(_version('1.0.0')), isFalse);
      expect(range.contains(_version('2.0.0')), isTrue);
    });

    test('a missing upper bound is unbounded above', () {
      final SemanticVersionRange range = _range('[1.2,)');

      expect(range.contains(_version('99.0.0')), isTrue);
      expect(range.contains(_version('1.1.0')), isFalse);
    });

    test('a missing lower bound is unbounded below', () {
      final SemanticVersionRange range = _range('(,2.0]');

      expect(range.contains(_version('0.0.1')), isTrue);
      expect(range.contains(_version('2.0.1')), isFalse);
    });

    test('a single bound in brackets is exactly that version', () {
      final SemanticVersionRange range = _range('[1.4.0]');

      expect(range.contains(_version('1.4.0')), isTrue);
      expect(range.contains(_version('1.4.1')), isFalse);
      expect(range, SemanticVersionRange.exactly(_version('1.4.0')));
    });

    test('shortened bounds mean the same as written out', () {
      expect(_range('[1.2, 2)'), _range('[1.2.0,2.0.0)'));
    });

    test('several intervals separated by commas are a union, as Maven '
        'writes them', () {
      final SemanticVersionRange range = _range('[1.0,2.0), [3.0,4.0)');

      expect(range.contains(_version('1.5.0')), isTrue);
      expect(range.contains(_version('2.5.0')), isFalse);
      expect(range.contains(_version('3.5.0')), isTrue);
      expect(range.intervals, hasLength(2));
    });

    test('surrounding whitespace is tolerated', () {
      expect(_range('  [1.2, 2.0)  '), _range('[1.2, 2.0)'));
    });

    test('renders in the canonical form', () {
      expect(_range('[1.2, 2.0)').toString(), '[1.2.0,2.0.0)');
      expect(_range('(,2]').toString(), '(,2.0.0]');
      expect(_range('[1.4.0]').toString(), '[1.4.0]');
      expect(_range('[3,4), [1,2)').toString(), '[1.0.0,2.0.0),[3.0.0,4.0.0)');
      expect(SemanticVersionRange.any.toString(), '(,)');
      expect(SemanticVersionRange.none.toString(), '[]');
    });

    test('places a pre-release by precedence, so it precedes its '
        'release', () {
      expect(_range('[1.2, 2.0)').contains(_version('2.0.0-rc.1')), isTrue);
    });

    test('ignores build metadata in a bound, as precedence does', () {
      expect(_range('[1.2.0+sha.1, 2.0.0+sha.2)'), _range('[1.2, 2.0)'));
    });
  });

  group('what is refused', () {
    test('text that is not in interval form', () {
      const refused = <String>[
        '[1.2',
        '1.2)',
        '[1.0,2.0,3.0)',
        '[1.0)',
        '[,1.0]',
        '[1.0,]',
        '[1,2) [3,4)',
        '[1,2),',
      ];
      for (final text in refused) {
        expect(SemanticVersionRange.tryParse(text), isNull, reason: text);
      }
    });

    test('nothing at all', () {
      for (final text in <String>['', '   ']) {
        expect(SemanticVersionRange.tryParse(text), isNull, reason: text);
      }
    });

    test('a bound that is not a version', () {
      expect(
        () => _range('[1.x, 2.0)'),
        throwsA(
          isA<FormatException>().having(
            (refusal) => refusal.message,
            'message',
            'Not a version range: it has a bound that is not a version: it '
                'must start with three dot-separated numbers, such as 1.4.0',
          ),
        ),
      );
    });

    test('a shortened bound carrying a pre-release', () {
      expect(SemanticVersionRange.tryParse('[1.2-rc.1, 2.0)'), isNull);
    });

    test('an interval with nothing in it', () {
      expect(SemanticVersionRange.tryParse('[2.0, 1.0)'), isNull);
      expect(SemanticVersionRange.tryParse('(1.0, 1.0)'), isNull);
    });

    test('an interval with no version between its exclusive bounds', () {
      expect(SemanticVersionRange.tryParse('(1.2.3, 1.2.4-0)'), isNull);
    });

    test('text longer than the limit, before it is split', () {
      final long = '${'^1.2 || ' * 200}^1.2';

      expect(
        () => _range(long),
        throwsA(
          isA<FormatException>().having(
            (refusal) => refusal.message,
            'message',
            'Not a version range: it is longer than 1024 characters',
          ),
        ),
      );
    });
  });

  group('stating one', () {
    test('between is closed below and open above', () {
      final range = SemanticVersionRange.between(
        _version('1.2.0'),
        _version('2.0.0'),
      );

      expect(range, _range('[1.2, 2.0)'));
    });

    test('between with no upper bound is open-ended', () {
      final range = SemanticVersionRange.between(_version('1.2.0'), null);

      expect(range.contains(_version('50.0.0')), isTrue);
    });

    test('atLeast and below are the two halves', () {
      expect(
        SemanticVersionRange.atLeast(_version('1.2.0')),
        _range('>=1.2.0'),
      );
      expect(SemanticVersionRange.below(_version('2.0.0')), _range('<2.0.0'));
    });

    test('caret and tilde mean what their notation means', () {
      expect(SemanticVersionRange.caret(_version('1.2.3')), _range('^1.2.3'));
      expect(SemanticVersionRange.caret(_version('0.0.3')), _range('^0.0.3'));
      expect(SemanticVersionRange.tilde(_version('1.2.3')), _range('~1.2.3'));
    });

    test('an empty range is refused', () {
      expect(
        () =>
            SemanticVersionRange.between(_version('2.0.0'), _version('2.0.0')),
        throwsArgumentError,
      );
    });

    test('nothing lies below the lowest version there is', () {
      expect(
        () => SemanticVersionRange.below(_version('0.0.0-0')),
        throwsArgumentError,
      );
    });

    test('any version is in any', () {
      expect(
        SemanticVersionRange.any.contains(_version('0.0.0-alpha')),
        isTrue,
      );
      expect(SemanticVersionRange.any.isAny, isTrue);
    });

    test('a lower bound of the lowest version there is holds every version '
        'and still names it', () {
      final SemanticVersionRange lowest = _range('>=0.0.0-0');

      expect(lowest.contains(_version('0.0.0-0')), isTrue);
      expect(
        lowest.contains(_version('0.0.0-alpha'), PreReleasePolicy.sameCoreOnly),
        isTrue,
      );
      expect(
        SemanticVersionRange.any.contains(
          _version('0.0.0-alpha'),
          PreReleasePolicy.sameCoreOnly,
        ),
        isFalse,
      );
    });
  });

  group('equality', () {
    test('two ranges holding the same versions are equal however they were '
        'written', () {
      expect(_range('^1.2.3'), _range('>=1.2.3 <2.0.0-0'));
      expect(_range('^1.2.3'), _range('[1.2.3, 2.0.0-0)'));
      expect(_range('<=1.2.3'), _range('<1.2.4-0'));
      expect(_range('1.2.3'), _range('[1.2.3]'));
    });

    test('a lower bound just above a release stays apart from the '
        'pre-release floor after it', () {
      final SemanticVersionRange above = _range('>1.2.3');
      final SemanticVersionRange floor = _range('>=1.2.4-0');
      final SemanticVersion preRelease = _version('1.2.4-beta');

      expect(above == floor, isFalse);
      expect(above.contains(preRelease), floor.contains(preRelease));
      expect(
        above.contains(preRelease, PreReleasePolicy.sameCoreOnly),
        isFalse,
      );
      expect(floor.contains(preRelease, PreReleasePolicy.sameCoreOnly), isTrue);
      expect(floor.toString(), '[1.2.4-0,)');
    });

    test('equal ranges hash alike', () {
      expect(_range('^1.2.3').hashCode, _range('[1.2.3, 2.0.0-0)').hashCode);
    });

    test('a bound is stated from the side that names the version '
        'written', () {
      final VersionInterval interval = _range('>1.2.3').intervals.single;

      expect(interval.lower, _version('1.2.3'));
      expect(interval.lowerInclusive, isFalse);
      expect(interval.upper, isNull);
    });

    test('an exclusive upper bound that is a pre-release floor stays as '
        'written', () {
      final VersionInterval interval = _range('^1.2.3').intervals.single;

      expect(interval.upper, _version('2.0.0-0'));
      expect(interval.upperInclusive, isFalse);
    });
  });
}
