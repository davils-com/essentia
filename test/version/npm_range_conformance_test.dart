/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/version/semantic_version_range.dart';
import 'package:test/test.dart';

/// Caret ranges and what node-semver desugars them to.
const _carets = <(String, String)>[
  ('^1.2.3', '>=1.2.3 <2.0.0-0'),
  ('^0.2.3', '>=0.2.3 <0.3.0-0'),
  ('^0.0.3', '>=0.0.3 <0.0.4-0'),
  ('^1.2.3-beta.2', '>=1.2.3-beta.2 <2.0.0-0'),
  ('^0.0.3-beta', '>=0.0.3-beta <0.0.4-0'),
  ('^1.2.x', '>=1.2.0 <2.0.0-0'),
  ('^0.0.x', '>=0.0.0 <0.1.0-0'),
  ('^0.0', '>=0.0.0 <0.1.0-0'),
  ('^1.x', '>=1.0.0 <2.0.0-0'),
  ('^0.x', '>=0.0.0 <1.0.0-0'),
];

/// Tilde ranges and what node-semver desugars them to.
const _tildes = <(String, String)>[
  ('~1.2.3', '>=1.2.3 <1.3.0-0'),
  ('~1.2', '>=1.2.0 <1.3.0-0'),
  ('~1', '>=1.0.0 <2.0.0-0'),
  ('~0.2.3', '>=0.2.3 <0.3.0-0'),
  ('~0.2', '>=0.2.0 <0.3.0-0'),
  ('~0', '>=0.0.0 <1.0.0-0'),
  ('~1.2.3-beta.2', '>=1.2.3-beta.2 <1.3.0-0'),
];

/// X-ranges and partial versions, and what node-semver desugars them to.
const _xRanges = <(String, String)>[
  ('1.x', '>=1.0.0 <2.0.0-0'),
  ('1.2.x', '>=1.2.0 <1.3.0-0'),
  ('1.X', '>=1.0.0 <2.0.0-0'),
  ('1.2.*', '>=1.2.0 <1.3.0-0'),
  ('1', '>=1.0.0 <2.0.0-0'),
  ('1.2', '>=1.2.0 <1.3.0-0'),
  ('=1.2', '>=1.2.0 <1.3.0-0'),
];

/// Primitive comparators with partial versions, and what node-semver
/// desugars them to.
const _primitives = <(String, String)>[
  ('>1', '>=2.0.0'),
  ('>1.2', '>=1.3.0'),
  ('>=1.2', '>=1.2.0'),
  ('<1.2', '<1.2.0-0'),
  ('<=1.2', '<1.3.0-0'),
  ('<1', '<1.0.0-0'),
  ('<=1', '<2.0.0-0'),
  ('>= 1.2.3', '>=1.2.3'),
  ('=1.2.3', '1.2.3'),
  ('1.2.3+build.5', '1.2.3'),
];

/// Hyphen ranges and what node-semver desugars them to.
const _hyphens = <(String, String)>[
  ('1.2.3 - 2.3.4', '>=1.2.3 <=2.3.4'),
  ('1.2 - 2.3.4', '>=1.2.0 <=2.3.4'),
  ('1.2.3 - 2.3', '>=1.2.3 <2.4.0-0'),
  ('1.2.3 - 2', '>=1.2.3 <3.0.0-0'),
  ('* - 2', '<3.0.0-0'),
  ('1.2.3 - *', '>=1.2.3'),
];

/// Ranges and their canonical interval form.
const _canonical = <(String, String)>[
  ('^1.2.3', '[1.2.3,2.0.0-0)'),
  ('^0.0.3', '[0.0.3]'),
  ('~1.2', '[1.2.0,1.3.0-0)'),
  ('1.2.3', '[1.2.3]'),
  ('>1.2.3', '(1.2.3,)'),
  ('<=1.2.3', '(,1.2.3]'),
  ('>1.2.3-alpha.3', '(1.2.3-alpha.3,)'),
  ('*', '(,)'),
  ('x', '(,)'),
  ('>=*', '(,)'),
  ('1.2.7 || >=1.2.9 <2.0.0', '[1.2.7],[1.2.9,2.0.0)'),
  ('^1.2 || ^2', '[1.2.0,2.0.0-0),[2.0.0,3.0.0-0)'),
  ('>=1 <3 || >=2 <4', '[1.0.0,4.0.0-0)'),
  ('<=1.0.0 || >1.0.0', '(,)'),
  ('[1.0,2.0) || ^3', '[1.0.0,2.0.0),[3.0.0,4.0.0-0)'),
];

/// Texts npm would not read, or reads as matching nothing.
const _refused = <String>[
  '1.2.3 ||',
  '|| 1.2.3',
  '>',
  '>= ',
  '1.x.3',
  '01.2',
  '1.2.3.4',
  '>2 <1',
  '<0.0.0-0',
  '>*',
  '<*',
  '1.2.3 -',
  '- 1.2',
  '1 - 2 - 3',
  '>=1 - 2',
  'v1.2.3',
  '~>1.2',
  '=>1.2',
  '1.2-rc.1',
  '^1.2.3-',
  '1.2.3 || >2 <1',
  '1.a',
];

/// Reads [text] as a range.
///
/// Returns the range.
SemanticVersionRange _parsed(String text) => SemanticVersionRange.parse(text);

/// Expects every shorthand of [table] to mean what it desugars to.
void _expectDesugaring(List<(String, String)> table) {
  for (final (shorthand, desugared) in table) {
    expect(
      _parsed(shorthand),
      _parsed(desugared),
      reason: '$shorthand should mean $desugared',
    );
  }
}

/// Matches a [FormatException] whose message matches [message].
///
/// Returns the matcher.
Matcher _refusedWith(Object message) => throwsA(
  isA<FormatException>().having(
    (refusal) => refusal.message,
    'message',
    message,
  ),
);

/// Tests that every shorthand means what node-semver makes of it.
void main() {
  group('each shorthand means what node-semver makes of it', () {
    test('caret ranges', () => _expectDesugaring(_carets));

    test('tilde ranges', () => _expectDesugaring(_tildes));

    test('x-ranges and partial versions', () => _expectDesugaring(_xRanges));

    test(
      'primitive comparators with partial versions',
      () => _expectDesugaring(_primitives),
    );

    test('hyphen ranges', () => _expectDesugaring(_hyphens));
  });

  group('the canonical form', () {
    test('renders each range as its one interval form', () {
      for (final (written, rendered) in _canonical) {
        expect(_parsed(written).toString(), rendered, reason: written);
      }
    });

    test('reads back to an equal range', () {
      for (final (written, _) in _canonical) {
        final SemanticVersionRange range = _parsed(written);

        expect(_parsed(range.toString()), range, reason: written);
      }
    });
  });

  group('what is refused', () {
    test('everything npm would not read, or reads as matching nothing', () {
      for (final String text in _refused) {
        expect(SemanticVersionRange.tryParse(text), isNull, reason: text);
      }
    });

    test('a comparator that is not a version says what was wrong with '
        'it', () {
      expect(
        () => _parsed('>=01.2'),
        _refusedWith(
          'Not a version range: it has a comparator that is not a version: '
          'it has a number with a leading zero',
        ),
      );
    });

    test('a range that cannot be met says so', () {
      expect(
        () => _parsed('>=2 <1'),
        _refusedWith(
          'Not a version range: it has an alternative that matches no '
          'version',
        ),
      );
    });

    test('a wildcard in the middle is refused rather than read as the line '
        'before it', () {
      expect(
        () => _parsed('1.x.3'),
        _refusedWith(
          startsWith(
            'Not a version range: it has a comparator that is not a version',
          ),
        ),
      );
    });
  });
}
