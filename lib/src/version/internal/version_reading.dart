/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// What came of reading a text as a semantic version: the version, or why
/// it is not one.
@internal
@immutable
sealed class VersionReading {
  /// Creates the reading.
  const VersionReading();
}

/// A text that was a semantic version, split into its parts.
@internal
@immutable
final class VersionRead extends VersionReading {
  /// Creates the reading of a version of [major], [minor] and [patch],
  /// with the [preRelease] and [build] identifiers.
  const VersionRead(
    this.major,
    this.minor,
    this.patch,
    this.preRelease,
    this.build,
  );

  /// The major version.
  final int major;

  /// The minor version.
  final int minor;

  /// The patch version.
  final int patch;

  /// The pre-release identifiers, empty for a release.
  final List<String> preRelease;

  /// The build metadata identifiers, empty when there are none.
  final List<String> build;
}

/// A text that was not a semantic version.
@internal
@immutable
final class VersionRefused extends VersionReading {
  /// Creates the refusal saying [reason].
  const VersionRefused(this.reason);

  /// What was wrong, phrased to follow `it`: `has a number with a leading
  /// zero`.
  final String reason;
}
