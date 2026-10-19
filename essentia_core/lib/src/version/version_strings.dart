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

import 'package:essentia_core/src/version/semantic_version.dart';
import 'package:essentia_core/src/version/semantic_version_range.dart';

/// Reads text as a semantic version or a version range.
///
/// ```dart
/// final shell = '1.4.0'.toSemanticVersion();
/// final supported = '^1.2 || ^2'.toSemanticVersionRange();
/// ```
extension VersionStrings on String {
  /// Reads this text, such as `1.4.0` or `2.0.0-rc.1+sha.9f3c`, as a
  /// semantic version, like [SemanticVersion.parse].
  ///
  /// Returns the version.
  ///
  /// Throws a [FormatException] if the text is not a semantic version. The
  /// message says what was wrong and does not quote the text.
  SemanticVersion toSemanticVersion() => SemanticVersion.parse(this);

  /// Reads this text as a semantic version, or answers `null` when it is
  /// not one, like [SemanticVersion.tryParse].
  ///
  /// Returns the version, or `null`.
  SemanticVersion? toSemanticVersionOrNull() => SemanticVersion.tryParse(this);

  /// Reads this text, such as `^1.2`, `>=1.2.0 <2.0.0` or `[1.2, 2.0)`, as
  /// a version range in either notation, like [SemanticVersionRange.parse].
  ///
  /// Returns the range.
  ///
  /// Throws a [FormatException] if the text is not a range, or matches no
  /// version. The message says what was wrong and does not quote the text.
  SemanticVersionRange toSemanticVersionRange() =>
      SemanticVersionRange.parse(this);

  /// Reads this text as a version range, or answers `null` when it is not
  /// one, like [SemanticVersionRange.tryParse].
  ///
  /// Returns the range, or `null`.
  SemanticVersionRange? toSemanticVersionRangeOrNull() =>
      SemanticVersionRange.tryParse(this);
}
