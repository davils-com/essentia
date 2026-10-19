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
