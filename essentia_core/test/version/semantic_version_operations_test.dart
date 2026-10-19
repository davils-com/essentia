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

import 'package:essentia_core/src/version/semantic_version.dart';
import 'package:essentia_core/src/version/semantic_version_range.dart';
import 'package:essentia_core/src/version/version_strings.dart';
import 'package:test/test.dart';

/// The largest number a version may hold.
const _largest = 2147483647;

/// Reads [text] as a version.
///
/// Returns the version.
SemanticVersion _version(String text) => SemanticVersion.parse(text);

/// Reads every one of [texts] as a version.
///
/// Returns the versions, in order.
List<SemanticVersion> _versions(List<String> texts) =>
    texts.map(_version).toList();

/// Expects [step] to take each first version of [steps] to the second.
void _expectSteps(
  List<(String, String)> steps,
  SemanticVersion Function(SemanticVersion version) step,
) {
  for (final (from, to) in steps) {
    expect(step(_version(from)), _version(to), reason: from);
  }
}

/// Tests the next versions, reshaping, stability, compatibility, the two
/// orderings and reading from a string.
void main() {
  group('the next major, minor and patch', () {
    test('raise the number and reset what follows it', () {
      _expectSteps(<(String, String)>[
        ('1.4.2', '2.0.0'),
        ('0.9.9', '1.0.0'),
      ], (version) => version.nextMajor());
      _expectSteps(<(String, String)>[
        ('1.4.2', '1.5.0'),
        ('1.0.0', '1.1.0'),
      ], (version) => version.nextMinor());
      _expectSteps(<(String, String)>[
        ('1.4.2', '1.4.3'),
        ('1.4.0', '1.4.1'),
      ], (version) => version.nextPatch());
    });

    test('release a pre-release of that step rather than skipping past '
        'it', () {
      _expectSteps(<(String, String)>[
        ('2.0.0-rc.2', '2.0.0'),
        ('1.5.0-beta', '2.0.0'),
      ], (version) => version.nextMajor());
      _expectSteps(<(String, String)>[
        ('1.5.0-beta', '1.5.0'),
        ('1.5.1-beta', '1.6.0'),
      ], (version) => version.nextMinor());
      _expectSteps(<(String, String)>[
        ('1.5.1-beta', '1.5.1'),
        ('1.5.0-rc.1', '1.5.0'),
      ], (version) => version.nextPatch());
    });

    test('drop build metadata, because a new version is a new build', () {
      expect(_version('1.4.2+sha.9f3c').nextPatch(), _version('1.4.3'));
    });

    test('refuse to raise a number past the largest one there is', () {
      final largest = SemanticVersion.of(
        _largest,
        minor: _largest,
        patch: _largest,
      );

      expect(largest.nextMajor, throwsStateError);
      expect(largest.nextMinor, throwsStateError);
      expect(largest.nextPatch, throwsStateError);
    });
  });

  group('the next pre-release', () {
    test('raises the last numeric identifier', () {
      _expectSteps(<(String, String)>[
        ('1.0.0-rc.1', '1.0.0-rc.2'),
        ('1.0.0-beta.9', '1.0.0-beta.10'),
        ('1.0.0-0', '1.0.0-1'),
      ], (version) => version.nextPreRelease());
    });

    test('raises a number of any length without overflowing', () {
      expect(
        _version('1.0.0-rc.99999999999999999999').nextPreRelease(),
        _version('1.0.0-rc.100000000000000000000'),
      );
    });

    test('raises the last numeric identifier even when a word follows '
        'it', () {
      expect(
        _version('1.0.0-alpha.1.nightly').nextPreRelease(),
        _version('1.0.0-alpha.2.nightly'),
      );
    });

    test('gives a line without a number its first one', () {
      expect(_version('1.0.0-rc').nextPreRelease(), _version('1.0.0-rc.1'));
    });

    test('refuses to continue a line a release does not have', () {
      expect(_version('1.0.0').nextPreRelease, throwsStateError);
    });

    test('with the label the line already has continues it', () {
      expect(
        _version('1.0.0-rc.1').nextPreRelease('rc'),
        _version('1.0.0-rc.2'),
      );
    });

    test('with a later label moves to that label on the same version', () {
      expect(
        _version('1.0.0-beta.3').nextPreRelease('rc'),
        _version('1.0.0-rc.1'),
      );
    });

    test('with an earlier label is refused, because it would go '
        'backwards', () {
      expect(
        () => _version('1.0.0-rc.1').nextPreRelease('alpha'),
        throwsArgumentError,
      );
    });

    test('from a release starts the line on the next patch', () {
      expect(_version('1.2.3').nextPreRelease('rc'), _version('1.2.4-rc.1'));
    });

    test('refuses a label that is not a pre-release identifier', () {
      expect(
        () => _version('1.2.3').nextPreRelease('r c'),
        throwsArgumentError,
      );
      expect(() => _version('1.2.3').nextPreRelease('01'), throwsArgumentError);
    });
  });

  group('reshaping', () {
    test('release drops the pre-release and the build', () {
      expect(_version('2.0.0-rc.1+sha.9f3c').release(), _version('2.0.0'));
    });

    test('release of a plain release is that release', () {
      final SemanticVersion plain = _version('2.0.0');

      expect(plain.release(), same(plain));
    });

    test('withoutBuild keeps the pre-release', () {
      expect(
        _version('2.0.0-rc.1+sha.9f3c').withoutBuild(),
        _version('2.0.0-rc.1'),
      );
    });

    test('withPreRelease replaces it and keeps the build', () {
      expect(
        _version('2.0.0-rc.1+sha.9f3c').withPreRelease(<String>['rc', '2']),
        _version('2.0.0-rc.2+sha.9f3c'),
      );
      expect(_version('2.0.0-rc.1').withPreRelease(), _version('2.0.0'));
    });

    test('withBuild replaces it and keeps the pre-release', () {
      expect(
        _version('2.0.0-rc.1').withBuild(<String>['sha', '1a2b']),
        _version('2.0.0-rc.1+sha.1a2b'),
      );
    });

    test('an identifier that is not one is refused', () {
      expect(
        () => _version('2.0.0').withPreRelease(<String>['01']),
        throwsArgumentError,
      );
      expect(
        () => _version('2.0.0').withBuild(<String>['']),
        throwsArgumentError,
      );
    });
  });

  group('stability', () {
    test('a release past 0.y.z is stable', () {
      expect(_version('1.0.0').isStable, isTrue);
    });

    test('initial development and pre-releases are not', () {
      expect(_version('0.9.0').isStable, isFalse);
      expect(_version('1.0.0-rc.1').isStable, isFalse);
    });
  });

  group('compatibility', () {
    test('a later version of the same major stands in for an earlier '
        'one', () {
      expect(_version('1.9.0').isCompatibleWith(_version('1.2.0')), isTrue);
      expect(_version('1.2.0').isCompatibleWith(_version('1.9.0')), isFalse);
      expect(_version('2.0.0').isCompatibleWith(_version('1.2.0')), isFalse);
    });

    test('below 1.0.0 the minor is the compatibility line', () {
      expect(_version('0.2.5').isCompatibleWith(_version('0.2.3')), isTrue);
      expect(_version('0.3.0').isCompatibleWith(_version('0.2.3')), isFalse);
    });

    test('below 0.1.0 a version stands in only for itself', () {
      expect(_version('0.0.3').isCompatibleWith(_version('0.0.3')), isTrue);
      expect(_version('0.0.4').isCompatibleWith(_version('0.0.3')), isFalse);
    });

    test('a pre-release stands in only for a pre-release of the same '
        'version', () {
      expect(
        _version('1.2.3-rc.2').isCompatibleWith(_version('1.2.3-rc.1')),
        isTrue,
      );
      expect(
        _version('1.3.0-beta').isCompatibleWith(_version('1.2.0')),
        isFalse,
      );
    });

    test('a build of a version stands in for another build of it', () {
      expect(_version('1.2.0+b').isCompatibleWith(_version('1.2.0+a')), isTrue);
    });
  });

  group('the two orderings', () {
    test('precedence does not tell builds apart', () {
      expect(
        SemanticVersion.precedence(_version('1.0.0+a'), _version('1.0.0+b')),
        0,
      );
    });

    test('the total order does, and agrees with equality', () {
      expect(
        SemanticVersion.totalOrder(_version('1.0.0+a'), _version('1.0.0+b')),
        -1,
      );
      expect(
        SemanticVersion.totalOrder(_version('1.0.0+a'), _version('1.0.0+a')),
        0,
      );
    });

    test('the total order puts no build first, and numeric identifiers '
        'numerically', () {
      final List<SemanticVersion> sorted = _versions(<String>[
        '1.0.0+10',
        '1.0.0+b',
        '1.0.0',
        '1.0.0+9',
        '0.9.0+z',
      ])..sort(SemanticVersion.totalOrder);

      expect(
        sorted,
        _versions(<String>[
          '0.9.0+z',
          '1.0.0',
          '1.0.0+9',
          '1.0.0+10',
          '1.0.0+b',
        ]),
      );
    });
  });

  group('reading from a string', () {
    test('reads a version and a range', () {
      expect('1.4.0'.toSemanticVersion(), SemanticVersion.of(1, minor: 4));
      expect(
        '^1.2'.toSemanticVersionRange(),
        SemanticVersionRange.parse('>=1.2.0 <2.0.0-0'),
      );
    });

    test('answers null for what is not one', () {
      expect('v1.4.0'.toSemanticVersionOrNull(), isNull);
      expect('>2 <1'.toSemanticVersionRangeOrNull(), isNull);
    });

    test('throws for what is not one', () {
      expect('v1.4.0'.toSemanticVersion, throwsFormatException);
      expect(''.toSemanticVersionRange, throwsFormatException);
    });
  });
}
