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

import 'dart:math';

import 'package:essentia_core/src/version/semantic_version.dart';
import 'package:essentia_core/src/version/semantic_version_range.dart';
import 'package:test/test.dart';

/// How many cases each property is checked against.
const _cases = 500;

/// The identifiers a pre-release or a build is drawn from.
const _identifiers = <String>[
  'alpha',
  'beta',
  'rc',
  '0',
  '1',
  '2',
  '11',
  'x-y',
];

/// Draws up to three identifiers from [random].
///
/// Returns the identifiers.
List<String> _randomIdentifiers(Random random) => <String>[
  for (var count = random.nextInt(4); count > 0; count--)
    _identifiers[random.nextInt(_identifiers.length)],
];

/// Draws a version with small numbers, a pre-release and a build from
/// [random].
///
/// Returns the version.
SemanticVersion _randomVersion(Random random) => SemanticVersion.of(
  random.nextInt(4),
  minor: random.nextInt(4),
  patch: random.nextInt(4),
  preRelease: _randomIdentifiers(random),
  build: _randomIdentifiers(random),
);

/// The sign of [comparison]: -1, 0 or 1.
///
/// Returns the sign.
int _sign(int comparison) => comparison.clamp(-1, 1);

/// Tests the properties every version has, against randomly drawn ones.
void main() {
  test('every version reads back from its own text form', () {
    final random = Random(11);
    for (var round = 0; round < _cases; round++) {
      final SemanticVersion version = _randomVersion(random);

      expect(SemanticVersion.parse(version.toString()), version);
    }
  });

  test('comparison is antisymmetric', () {
    final random = Random(12);
    for (var round = 0; round < _cases; round++) {
      final SemanticVersion left = _randomVersion(random);
      final SemanticVersion right = _randomVersion(random);

      expect(_sign(left.compareTo(right)), -_sign(right.compareTo(left)));
    }
  });

  test('comparison is transitive', () {
    final random = Random(13);
    for (var round = 0; round < _cases; round++) {
      final sorted = <SemanticVersion>[
        _randomVersion(random),
        _randomVersion(random),
        _randomVersion(random),
      ]..sort();

      expect(sorted[0] <= sorted[2], isTrue);
    }
  });

  test('a version is in the range from itself to its successor and not in '
      'the one after', () {
    final random = Random(14);
    for (var round = 0; round < _cases; round++) {
      final SemanticVersion version = _randomVersion(random);
      final next = SemanticVersion.of(
        version.major,
        minor: version.minor,
        patch: version.patch + 1,
      );
      final range = SemanticVersionRange.between(version, next);

      expect(range.contains(version), isTrue);
      expect(range.contains(next), isFalse);
    }
  });
}
