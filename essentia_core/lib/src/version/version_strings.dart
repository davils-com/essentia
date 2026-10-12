/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/version/semantic_version.dart';
import 'package:essentia_core/src/version/semantic_version_range.dart';

/// Reads text as a semantic version or a version range, Arc's `String`
/// extensions.
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
