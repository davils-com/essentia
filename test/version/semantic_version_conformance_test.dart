/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

import 'package:essentia/src/version/semantic_version.dart';
import 'package:test/test.dart';

/// How many texts each property is checked against.
const _cases = 5000;

/// The longest text a version may be.
const _longest = 256;

/// The largest number a version may hold.
const _largest = 2147483647;

/// How small a share of the cases each answer has to be at least: one in
/// twenty.
const _minimumShare = 20;

/// The regular expression published at semver.org.
final _official = RegExp(
  r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'
  r'(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)'
  r'(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?'
  r'(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$',
);

/// The characters the texts are made of.
const _alphabet = '0123456789.-+aZx';

/// The identifiers a pre-release or a build is drawn from, valid or not.
const _identifier = <String>[
  '0',
  '1',
  '01',
  '9',
  '10',
  'alpha',
  'rc',
  'x-y',
  '-',
  '0a',
  '',
];

/// The odd numerals a number is drawn from.
const _oddNumerals = <String>['00', '01', ''];

/// Picks one element of [options] from [random].
///
/// Returns the element.
T _pick<T>(Random random, List<T> options) =>
    options[random.nextInt(options.length)];

/// Draws up to 24 characters of the alphabet from [random].
///
/// Returns the text.
String _noise(Random random) => <String>[
  for (var count = random.nextInt(25); count > 0; count--)
    _pick(random, _alphabet.split('')),
].join();

/// Draws one to three identifiers, joined by dots, from [random].
///
/// Returns the text.
String _identifiers(Random random) => <String>[
  for (var count = random.nextInt(3) + 1; count > 0; count--)
    _pick(random, _identifier),
].join('.');

/// Draws a number from [random]: a small one, one around the largest a
/// version may hold, or an odd one.
///
/// Returns the numeral.
String _numeral(Random random) {
  final int kind = random.nextInt(3);
  if (kind == 0) {
    return '${random.nextInt(13)}';
  }
  if (kind == 1) {
    return '${_largest - 2 + random.nextInt(5)}';
  }
  return _pick(random, _oddNumerals);
}

/// Draws a text shaped like a version, which may still be malformed, from
/// [random].
///
/// Returns the text.
String _shaped(Random random) {
  final String major = _numeral(random);
  final String minor = _numeral(random);
  final String patch = _numeral(random);
  final preRelease = random.nextBool() ? '-${_identifiers(random)}' : '';
  final build = random.nextBool() ? '+${_identifiers(random)}' : '';
  return '$major.$minor.$patch$preRelease$build';
}

/// Draws a version-shaped text with one character of the alphabet inserted
/// somewhere from [random].
///
/// Returns the text.
String _mutated(Random random) {
  final String text = _shaped(random);
  final int position = min(random.nextInt(41), text.length);
  final String character = _pick(random, _alphabet.split(''));
  return text.substring(0, position) + character + text.substring(position);
}

/// Draws a candidate text from [random]: noise, a version-shaped text, or
/// one with a character inserted.
///
/// Returns the text.
String _candidate(Random random) => _pick(random, _generators)(random);

/// The ways a candidate text is drawn.
const _generators = <String Function(Random random)>[_noise, _shaped, _mutated];

/// Whether [text] is a version by the published regular expression, with
/// numbers no larger than a version may hold.
///
/// Returns `true` for an official version.
bool _isOfficial(String text) {
  final RegExpMatch? match = _official.firstMatch(text);
  if (match == null) {
    return false;
  }
  final bool numbersFit = <int>[1, 2, 3].every((group) {
    final String number = match.group(group) ?? '';
    return number.length <= 10 && int.parse(number) <= _largest;
  });
  return numbersFit && text.length <= _longest;
}

/// Tests that reading agrees with the specification's own regular
/// expression.
void main() {
  test('accepts exactly what the regular expression published at semver.org '
      'accepts', () {
    final random = Random(21);
    var accepted = 0;
    for (var round = 0; round < _cases; round++) {
      final String text = _candidate(random);
      final bool official = _isOfficial(text);
      if (official) {
        accepted++;
      }

      expect(SemanticVersion.tryParse(text) != null, official, reason: text);
    }

    expect(
      accepted,
      inInclusiveRange(
        _cases ~/ _minimumShare,
        _cases - _cases ~/ _minimumShare,
      ),
      reason: 'the generated texts must exercise both answers',
    );
  });

  test('renders every version it accepts exactly as it was written', () {
    final random = Random(22);
    for (var round = 0; round < _cases; round++) {
      final String text = _candidate(random);
      final SemanticVersion? version = SemanticVersion.tryParse(text);
      if (version != null) {
        expect(version.toString(), text);
      }
    }
  });
}
