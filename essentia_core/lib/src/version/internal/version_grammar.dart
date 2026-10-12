/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/range/int_range_building.dart';
import 'package:essentia_core/src/version/internal/identifier_rules.dart';
import 'package:essentia_core/src/version/internal/version_reading.dart';
import 'package:meta/meta.dart';

/// The longest text read as a version, so that an absurd one is refused
/// before it is split.
const _maxLength = 256;

/// The largest number a version may hold, Kotlin's `Int.MAX_VALUE`, so that
/// a version reads the same on every platform and in Arc.
@internal
const maxNumber = 2147483647;

/// How many digits [maxNumber] has.
const _longestNumber = 10;

/// How many numbers a version starts with.
@internal
const coreSegments = 3;

/// What separates the pre-release from the numbers.
@internal
const preReleaseSeparator = '-';

/// What separates the build metadata from the rest.
@internal
const buildSeparator = '+';

/// What separates the numbers, and the identifiers of a pre-release or a
/// build.
@internal
const identifierSeparator = '.';

/// Why an empty text is not a version.
@internal
const emptyReason = 'is empty';

/// Why a text longer than [_maxLength] is not a version.
const _tooLongReason = 'is longer than $_maxLength characters';

/// Why a text without three numbers in front is not a version.
const _coreReason =
    'must start with three dot-separated numbers, such as 1.4.0';

/// Why a number with a leading zero is refused.
const _leadingZeroReason = 'has a number with a leading zero';

/// Why a number beyond [maxNumber] is refused.
const _tooLargeReason = 'has a number larger than $maxNumber';

/// Why a malformed pre-release is refused.
const _preReleaseReason = 'has an empty or malformed pre-release identifier';

/// Why malformed build metadata is refused.
const _buildReason = 'has an empty or malformed build identifier';

/// Reads [text] as a semantic version, strictly.
///
/// [minimumCoreSegments] lets a bound of the interval notation be
/// shortened to `1.2` or `1`; anything shortened carries neither a
/// pre-release nor a build.
///
/// Returns the version read, or why [text] is not one.
@internal
VersionReading readVersion(
  String text, [
  int minimumCoreSegments = coreSegments,
]) {
  if (text.isEmpty) {
    return const VersionRefused(emptyReason);
  }
  if (text.length > _maxLength) {
    return const VersionRefused(_tooLongReason);
  }

  final String? build = _partAfter(text, buildSeparator);
  final String withoutBuild = _partBefore(text, buildSeparator);
  final String? preRelease = _partAfter(withoutBuild, preReleaseSeparator);
  final String core = _partBefore(withoutBuild, preReleaseSeparator);

  final List<String>? buildIdentifiers = _identifiersOf(build);
  if (buildIdentifiers == null) {
    return const VersionRefused(_buildReason);
  }
  final List<String>? preReleaseIdentifiers = _identifiersOf(preRelease);
  if (preReleaseIdentifiers == null ||
      !preReleaseIdentifiers.every(isPreReleaseIdentifier)) {
    return const VersionRefused(_preReleaseReason);
  }
  return _readCore(
    core,
    minimumCoreSegments,
    preReleaseIdentifiers,
    buildIdentifiers,
  );
}

/// Says what is wrong with the pre-release [identifiers].
///
/// Returns the reason, or `null` when every one is a pre-release
/// identifier.
@internal
String? preReleaseProblem(List<String> identifiers) {
  if (identifiers.every(isPreReleaseIdentifier)) {
    return null;
  }
  return _preReleaseReason;
}

/// Says what is wrong with the build [identifiers].
///
/// Returns the reason, or `null` when every one is an identifier.
@internal
String? buildProblem(List<String> identifiers) {
  if (identifiers.every(isIdentifier)) {
    return null;
  }
  return _buildReason;
}

/// Says what is wrong with [segment] as one number of a version, with
/// [malformedReason] for a segment that is no number at all.
///
/// Returns the reason, or `null` for a number a version may hold.
@internal
String? numberProblem(String segment, [String malformedReason = _coreReason]) {
  if (segment.isEmpty || !isNumeral(segment)) {
    return malformedReason;
  }
  if (segment.length > 1 && segment.startsWith(zero)) {
    return _leadingZeroReason;
  }
  if (segment.length > _longestNumber || int.parse(segment) > maxNumber) {
    return _tooLargeReason;
  }
  return null;
}

/// Reads the numbers of [core], at least [minimumCoreSegments] of them,
/// completing the reading with [preRelease] and [build].
///
/// Returns the version read, or why [core] does not start one.
VersionReading _readCore(
  String core,
  int minimumCoreSegments,
  List<String> preRelease,
  List<String> build,
) {
  final List<String> segments = core.split(identifierSeparator);
  final bool segmentCountFits = minimumCoreSegments
      .rangeTo(coreSegments)
      .contains(segments.length);
  if (!segmentCountFits) {
    return const VersionRefused(_coreReason);
  }
  final bool shortened = segments.length < coreSegments;
  final bool qualified = preRelease.isNotEmpty || build.isNotEmpty;
  if (shortened && qualified) {
    return const VersionRefused(_coreReason);
  }

  final numbers = <int>[];
  for (final segment in segments) {
    final String? problem = numberProblem(segment);
    if (problem != null) {
      return VersionRefused(problem);
    }
    numbers.add(int.parse(segment));
  }
  final padded = <int>[
    ...numbers,
    ...List<int>.filled(coreSegments - numbers.length, 0),
  ];
  return VersionRead(padded[0], padded[1], padded[2], preRelease, build);
}

/// The part of [text] after the first [separator].
///
/// Returns the part, or `null` when [text] holds no [separator].
String? _partAfter(String text, String separator) {
  final int at = text.indexOf(separator);
  if (at < 0) {
    return null;
  }
  return text.substring(at + 1);
}

/// The part of [text] before the first [separator], Kotlin's
/// `substringBefore`.
///
/// Returns the part, or all of [text] when it holds no [separator].
String _partBefore(String text, String separator) {
  final int at = text.indexOf(separator);
  if (at < 0) {
    return text;
  }
  return text.substring(0, at);
}

/// Splits [part] into its dot-separated identifiers.
///
/// Returns the identifiers, none when [part] is `null`, or `null` when one
/// of them is not an identifier.
List<String>? _identifiersOf(String? part) {
  if (part == null) {
    return const <String>[];
  }
  final List<String> identifiers = part.split(identifierSeparator);
  if (!identifiers.every(isIdentifier)) {
    return null;
  }
  return identifiers;
}
