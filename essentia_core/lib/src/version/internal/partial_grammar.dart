/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/version/internal/partial.dart';
import 'package:essentia_core/src/version/internal/partial_reading.dart';
import 'package:essentia_core/src/version/internal/version_grammar.dart';
import 'package:essentia_core/src/version/internal/version_reading.dart';
import 'package:essentia_core/src/version/internal/version_steps.dart';
import 'package:essentia_core/src/version/semantic_version.dart';
import 'package:meta/meta.dart';

/// Why a wildcard followed by a number is refused.
const _wildcardReason = 'has a wildcard followed by a number, such as 1.x.3';

/// Why an operand that is no partial version is refused.
const _partialReason =
    'must be a version, or up to three numbers where x or * stands for any, '
    'such as 1.2.x';

/// What stands for any number.
const _wildcards = <String>{'x', 'X', '*'};

/// The partial version of the complete [version].
///
/// Returns the partial version, with all three numbers given.
@internal
Partial partialOf(SemanticVersion version) =>
    Partial(<int>[version.major, version.minor, version.patch], version);

/// Reads [text], the operand of a comparator, as a partial version: a
/// complete version, or up to three numbers ending in wildcards.
///
/// Returns the partial version read, or why [text] is not one.
@internal
PartialReading readPartial(String text) {
  final bool qualified =
      text.contains(preReleaseSeparator) || text.contains(buildSeparator);
  if (qualified) {
    return _readQualified(text);
  }

  final List<String> segments = text.split(identifierSeparator);
  if (segments.length > coreSegments) {
    return const PartialRefused(_partialReason);
  }
  final int wildcardAt = segments.indexWhere(_wildcards.contains);
  final List<String> given = wildcardAt < 0
      ? segments
      : segments.sublist(0, wildcardAt);
  final Iterable<String> wildcards = segments.skip(given.length);
  if (!wildcards.every(_wildcards.contains)) {
    return const PartialRefused(_wildcardReason);
  }

  for (final segment in given) {
    final String? problem = numberProblem(segment, _partialReason);
    if (problem != null) {
      return PartialRefused(problem);
    }
  }
  final List<int> numbers = given.map(int.parse).toList();
  final SemanticVersion? complete = numbers.length == coreSegments
      ? releaseFloor(numbers)
      : null;
  return PartialRead(Partial(numbers, complete));
}

/// Reads [text], which carries a pre-release or build metadata, as the
/// complete version it then has to be.
///
/// Returns the partial version read, or why [text] is not one.
PartialReading _readQualified(String text) {
  final VersionReading reading = readVersion(text);
  return switch (reading) {
    VersionRead() => PartialRead(
      partialOf(SemanticVersion.fromReading(reading)),
    ),
    VersionRefused(:final reason) => PartialRefused(reason),
  };
}
