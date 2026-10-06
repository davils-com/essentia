/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:math';

import 'package:essentia/src/range/int_progression.dart';
import 'package:meta/meta.dart';

/// The digit no number of more than one digit may start with.
@internal
const zero = '0';

/// The code unit of the hyphen, the one identifier character that is
/// neither a letter nor a digit.
const _hyphen = 0x2D;

/// The code units of the ASCII digits.
const _digits = IntRange(0x30, 0x39);

/// The code units of the ASCII lowercase letters.
const _lowercase = IntRange(0x61, 0x7A);

/// The code units of the ASCII uppercase letters.
const _uppercase = IntRange(0x41, 0x5A);

/// Compares the pre-releases [left] and [right] by precedence: a version
/// without one sorts above any version with one, and otherwise identifier
/// by identifier.
///
/// Returns a negative number, zero or a positive number when [left] comes
/// before, with or after [right].
@internal
int comparePreReleases(List<String> left, List<String> right) {
  if (left.isEmpty && right.isEmpty) {
    return 0;
  }
  if (left.isEmpty) {
    return 1;
  }
  if (right.isEmpty) {
    return -1;
  }
  return _compareIdentifierLists(left, right);
}

/// Compares the build metadata [left] and [right]: none first, then
/// identifier by identifier, numeric ones numerically and below
/// alphanumeric ones.
///
/// Returns a negative number, zero or a positive number when [left] comes
/// before, with or after [right].
@internal
int compareBuilds(List<String> left, List<String> right) =>
    _compareIdentifierLists(left, right);

/// Whether [identifier] is a non-empty run of `[0-9A-Za-z-]`, which every
/// pre-release and build identifier has to be.
///
/// Returns `true` for an identifier.
@internal
bool isIdentifier(String identifier) =>
    identifier.isNotEmpty && identifier.codeUnits.every(_isIdentifierCharacter);

/// Whether [identifier] may stand in a pre-release: an identifier, and
/// without a leading zero when it is numeric.
///
/// Returns `true` for a pre-release identifier.
@internal
bool isPreReleaseIdentifier(String identifier) {
  if (!isIdentifier(identifier)) {
    return false;
  }
  final bool numeric = isNumeral(identifier);
  return !numeric || identifier.length == 1 || !identifier.startsWith(zero);
}

/// Whether every character of [text] is an ASCII digit; `true` for the
/// empty text, as Kotlin's `all` is.
///
/// Returns `true` for a numeral.
@internal
bool isNumeral(String text) => text.codeUnits.every(_digits.contains);

/// Whether the code unit [character] may appear in an identifier.
///
/// Returns `true` for a digit, an ASCII letter or the hyphen.
bool _isIdentifierCharacter(int character) {
  if (_digits.contains(character)) {
    return true;
  }
  if (_lowercase.contains(character) || _uppercase.contains(character)) {
    return true;
  }
  return character == _hyphen;
}

/// Compares the identifier lists [left] and [right] identifier by
/// identifier; when one is a prefix of the other, the shorter one comes
/// first.
///
/// Returns a negative number, zero or a positive number when [left] comes
/// before, with or after [right].
int _compareIdentifierLists(List<String> left, List<String> right) {
  final int shared = min(left.length, right.length);
  for (var index = 0; index < shared; index++) {
    final int decided = _compareIdentifier(left[index], right[index]);
    if (decided != 0) {
      return decided;
    }
  }
  return left.length.compareTo(right.length);
}

/// Compares the identifiers [left] and [right]: numeric ones numerically
/// and below alphanumeric ones, alphanumeric ones in ASCII order.
///
/// Returns a negative number, zero or a positive number when [left] comes
/// before, with or after [right].
int _compareIdentifier(String left, String right) {
  final bool leftNumeric = isNumeral(left);
  final bool rightNumeric = isNumeral(right);
  if (leftNumeric && rightNumeric) {
    return _compareNumerals(left, right);
  }
  if (leftNumeric) {
    return -1;
  }
  if (rightNumeric) {
    return 1;
  }
  return left.compareTo(right);
}

/// Compares the numerals [left] and [right] by their value, however many
/// digits they have, without reading them as numbers.
///
/// Returns a negative number, zero or a positive number when [left] is
/// smaller than, equal to or larger than [right].
int _compareNumerals(String left, String right) {
  final int byLength = left.length.compareTo(right.length);
  if (byLength != 0) {
    return byLength;
  }
  return left.compareTo(right);
}
