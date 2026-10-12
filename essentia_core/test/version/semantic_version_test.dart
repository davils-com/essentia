/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/version/semantic_version.dart';
import 'package:test/test.dart';

/// The example list of the specification, in its order of precedence.
const _specificationOrder = <String>[
  '1.0.0-alpha',
  '1.0.0-alpha.1',
  '1.0.0-alpha.beta',
  '1.0.0-beta',
  '1.0.0-beta.2',
  '1.0.0-beta.11',
  '1.0.0-rc.1',
  '1.0.0',
  '2.0.0',
  '2.1.0',
  '2.1.1',
];

/// Versions the specification lists as valid.
const _valid = <String>[
  '0.0.0',
  '1.0.0-0.3.7',
  '1.0.0-x.7.z.92',
  '1.0.0-x-y-z.--',
  '1.0.0-alpha+001',
  '1.0.0+20130313144700',
  '1.0.0-beta+exp.sha.5114f85',
  '1.0.0+21AF26D3----117B344092BD',
];

/// Texts the specification refuses.
const _invalid = <String>[
  '',
  '1',
  '1.2',
  '1.2.3.4',
  'v1.0.0',
  ' 1.0.0',
  '1.0.0 ',
  '01.0.0',
  '1.00.0',
  '1.0.0-01',
  '1.0.0-',
  '1.0.0+',
  '1.0.0-alpha..1',
  '1.0.0+build..1',
  '1.0.0-al_pha',
  '99999999999.0.0',
  'a.b.c',
];

/// Matches a [FormatException] whose message is [message].
///
/// Returns the matcher.
Matcher _refusedWith(Object message) => throwsA(
  isA<FormatException>().having(
    (refusal) => refusal.message,
    'message',
    message,
  ),
);

/// Tests reading, ordering and stating a semantic version.
void main() {
  group('reading', () {
    test('every version the specification lists as valid is read back as '
        'written', () {
      for (final String text in _valid) {
        expect(SemanticVersion.parse(text).toString(), text);
      }
    });

    test('every text the specification refuses is refused', () {
      for (final String text in _invalid) {
        expect(SemanticVersion.tryParse(text), isNull, reason: text);
      }
    });

    test('a version is split into its parts', () {
      final version = SemanticVersion.parse('2.0.0-rc.1+sha.9f3c');

      expect(version.major, 2);
      expect(version.minor, 0);
      expect(version.patch, 0);
      expect(version.preRelease, <String>['rc', '1']);
      expect(version.build, <String>['sha', '9f3c']);
      expect(version.isPreRelease, isTrue);
    });

    test('a refusal says why without quoting the text', () {
      expect(
        () => SemanticVersion.parse('01.2.3'),
        _refusedWith(
          allOf(
            'Not a semantic version: it has a number with a leading zero',
            isNot(contains('01.2.3')),
          ),
        ),
      );
    });

    test('a very long text is refused before it is split', () {
      expect(
        () => SemanticVersion.parse('1' * 10000),
        _refusedWith(
          'Not a semantic version: it is longer than 256 characters',
        ),
      );
    });
  });

  group('precedence', () {
    test("orders the specification's example list exactly as the "
        'specification does', () {
      final List<SemanticVersion> sorted =
          _specificationOrder.reversed.map(SemanticVersion.parse).toList()
            ..sort();

      expect(sorted.map((version) => version.toString()), _specificationOrder);
    });

    test('puts a pre-release below the release it leads to', () {
      expect(
        SemanticVersion.parse('2.0.0-rc.1') < SemanticVersion.of(2),
        isTrue,
      );
    });

    test('compares numeric pre-release identifiers as numbers, however '
        'long', () {
      final short = SemanticVersion.parse('1.0.0-9');
      final long = SemanticVersion.parse('1.0.0-100000000000000000000');

      expect(short < long, isTrue);
    });

    test('ignores build metadata, while equality does not', () {
      final one = SemanticVersion.parse('1.0.0+a');
      final other = SemanticVersion.parse('1.0.0+b');

      expect(one.compareTo(other), 0);
      expect(one, isNot(other));
    });
  });

  group('stating one', () {
    test('fills in what is not given with zeros and nothing', () {
      final version = SemanticVersion.of(2);

      expect(version.toString(), '2.0.0');
      expect(version.isPreRelease, isFalse);
    });

    test('equals the same version read from text', () {
      expect(
        SemanticVersion.of(1, minor: 4, preRelease: const <String>['rc', '1']),
        SemanticVersion.parse('1.4.0-rc.1'),
      );
      expect(
        SemanticVersion.of(1, minor: 4).hashCode,
        SemanticVersion.parse('1.4.0').hashCode,
      );
    });

    test('refuses a negative number', () {
      expect(() => SemanticVersion.of(1, minor: -1), throwsArgumentError);
    });

    test('refuses a number larger than the largest 32-bit integer', () {
      expect(() => SemanticVersion.of(2147483648), throwsArgumentError);
    });

    test('refuses a malformed identifier', () {
      expect(
        () => SemanticVersion.of(1, preRelease: const <String>['01']),
        throwsArgumentError,
      );
      expect(
        () => SemanticVersion.of(1, build: const <String>['']),
        throwsArgumentError,
      );
    });

    test('keeps no reference to the list it was given', () {
      final identifiers = <String>['rc'];
      final version = SemanticVersion.of(1, preRelease: identifiers);

      identifiers.add('2');

      expect(version.preRelease, <String>['rc']);
    });
  });
}
