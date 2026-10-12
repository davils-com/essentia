/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/src/validation/validatable.dart';
import 'package:essentia_core/src/validation/validation_scope.dart';
import 'package:essentia_core/src/version/internal/range_grammar.dart';
import 'package:essentia_core/src/version/internal/range_reading.dart';
import 'package:essentia_core/src/version/internal/version_grammar.dart';
import 'package:essentia_core/src/version/internal/version_reading.dart';
import 'package:essentia_core/src/version/semantic_version.dart';
import 'package:essentia_core/src/version/semantic_version_range.dart';
import 'package:essentia_core/src/version/version_violation_codes.dart';

/// Reads versions and ranges inside a validation, reporting a malformed one
/// rather than throwing.
///
/// What a [Validatable] that carries a version as text needs: the version
/// joins the report beside every other problem instead of ending it.
///
/// ```dart
/// @override
/// void validate(ValidationScope scope) {
///   scope.semanticVersion(version, property: 'version');
///   scope.semanticVersionRange(requiresShell, property: 'requiresShell');
/// }
/// ```
extension VersionValidations on ValidationScope {
  /// Reads [text] as a semantic version, reporting under [property], the
  /// name of the property it was read from, why it is not one.
  ///
  /// The violation carries [VersionViolationCodes.invalidVersion].
  ///
  /// Returns the version, or `null` after reporting why [text] is not one.
  SemanticVersion? semanticVersion(String text, {required String property}) {
    final VersionReading reading = readVersion(text);
    switch (reading) {
      case VersionRead():
        return SemanticVersion.fromReading(reading);
      case VersionRefused(:final reason):
        fail(
          'is not a semantic version: it $reason',
          property: property,
          code: VersionViolationCodes.invalidVersion,
        );
        return null;
    }
  }

  /// Reads [text] as a version range, in either notation
  /// [SemanticVersionRange.parse] reads, such as `^1.2` or `[1.2, 2.0)`,
  /// reporting under [property], the name of the property it was read
  /// from, why it is not one or matches no version.
  ///
  /// The violation carries [VersionViolationCodes.invalidRange].
  ///
  /// Returns the range, or `null` after reporting why [text] is not one.
  SemanticVersionRange? semanticVersionRange(
    String text, {
    required String property,
  }) {
    final RangeReading reading = readRange(text);
    switch (reading) {
      case RangeRead():
        return SemanticVersionRange.fromReading(reading);
      case RangeRefused(:final reason):
        fail(
          'is not a version range: it $reason',
          property: property,
          code: VersionViolationCodes.invalidRange,
        );
        return null;
    }
  }
}
