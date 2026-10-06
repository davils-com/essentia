/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/version/internal/version_grammar.dart';
import 'package:essentia/src/version/semantic_version.dart';
import 'package:meta/meta.dart';

/// The lowest pre-release identifier there is.
const _zeroIdentifier = '0';

/// The code unit of the digit nine, which carries when raised.
const _nine = 0x39;

/// The code unit of the digit zero, what a carried nine becomes.
const _zeroDigit = 0x30;

/// The digit a numeral that carried past its first digit gains in front.
const _carry = '1';

/// The lowest version there is, `0.0.0-0`; nothing lies below it.
@internal
final minimum = SemanticVersion.of(
  0,
  preRelease: const <String>[_zeroIdentifier],
);

/// The version right after [version], with nothing between the two: `.0`
/// appended to a pre-release, and the pre-release floor of the next patch
/// for a release.
///
/// Returns the successor, or `null` when [version] is the last release
/// there is.
@internal
SemanticVersion? successor(SemanticVersion version) {
  if (version.isPreRelease) {
    return SemanticVersion.of(
      version.major,
      minor: version.minor,
      patch: version.patch,
      preRelease: <String>[...version.preRelease, _zeroIdentifier],
    );
  }
  return floorAbove(<int>[version.major, version.minor, version.patch]);
}

/// The version right before [version], when [version] is the [successor]
/// of one: `1.2.3` for `1.2.4-0`, `1.2.3-rc` for `1.2.3-rc.0`.
///
/// Returns the predecessor, or `null` when [version] is no successor.
@internal
SemanticVersion? predecessor(SemanticVersion version) {
  final List<String> identifiers = version.preRelease;
  if (identifiers.lastOrNull != _zeroIdentifier) {
    return null;
  }
  if (identifiers.length > 1) {
    return preReleasePredecessor(version);
  }
  if (version.patch == 0) {
    return null;
  }
  return SemanticVersion.of(
    version.major,
    minor: version.minor,
    patch: version.patch - 1,
  );
}

/// The pre-release right before [version], when [version] ends in a `.0`
/// that was appended to one: `1.2.3-rc` for `1.2.3-rc.0`.
///
/// Returns the predecessor, or `null` when [version] is no such successor.
@internal
SemanticVersion? preReleasePredecessor(SemanticVersion version) {
  final List<String> identifiers = version.preRelease;
  if (identifiers.length < 2 || identifiers.last != _zeroIdentifier) {
    return null;
  }
  return SemanticVersion.of(
    version.major,
    minor: version.minor,
    patch: version.patch,
    preRelease: identifiers.sublist(0, identifiers.length - 1),
  );
}

/// The lowest version above every version starting with [prefix]:
/// `2.0.0-0` for `[1]`, `1.3.0-0` for `[1, 2]`.
///
/// Returns the version, or `null` when no number of [prefix] can be raised.
@internal
SemanticVersion? floorAbove(List<int> prefix) {
  final int position = prefix.lastIndexWhere((number) => number < maxNumber);
  if (position < 0) {
    return null;
  }
  final raised = <int>[...prefix.take(position), prefix[position] + 1];
  return preReleaseFloor(raised);
}

/// The release [prefix] stands for, with zeros for the numbers it leaves
/// out: `1.2.0` for `[1, 2]`.
///
/// Returns the release.
@internal
SemanticVersion releaseFloor(List<int> prefix) {
  final List<int> numbers = _padded(prefix);
  return SemanticVersion.of(numbers[0], minor: numbers[1], patch: numbers[2]);
}

/// The lowest version starting with [prefix], the `-0` pre-release of
/// [releaseFloor]: `1.2.0-0` for `[1, 2]`.
///
/// Returns the version.
@internal
SemanticVersion preReleaseFloor(List<int> prefix) {
  final List<int> numbers = _padded(prefix);
  return SemanticVersion.of(
    numbers[0],
    minor: numbers[1],
    patch: numbers[2],
    preRelease: const <String>[_zeroIdentifier],
  );
}

/// Raises the [numeral] by one, digit by digit, so that a number of any
/// length is raised without overflowing.
///
/// Returns the raised numeral.
@internal
String incremented(String numeral) {
  final List<int> digits = numeral.codeUnits.toList();
  int position = digits.length - 1;
  while (position >= 0 && digits[position] == _nine) {
    digits[position] = _zeroDigit;
    position--;
  }
  if (position < 0) {
    return _carry + String.fromCharCodes(digits);
  }
  digits[position] = digits[position] + 1;
  return String.fromCharCodes(digits);
}

/// Completes [prefix] to all three numbers with zeros.
///
/// Returns the three numbers.
List<int> _padded(List<int> prefix) => <int>[
  ...prefix,
  ...List<int>.filled(coreSegments - prefix.length, 0),
];
