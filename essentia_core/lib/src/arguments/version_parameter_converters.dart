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

import 'package:essentia_core/src/arguments/conversion_exception.dart';
import 'package:essentia_core/src/arguments/parameter_builder.dart';
import 'package:essentia_core/src/arguments/parameter_converters.dart';
import 'package:essentia_core/src/version/internal/range_grammar.dart';
import 'package:essentia_core/src/version/internal/range_reading.dart';
import 'package:essentia_core/src/version/internal/version_grammar.dart';
import 'package:essentia_core/src/version/internal/version_reading.dart';
import 'package:essentia_core/src/version/semantic_version.dart';
import 'package:essentia_core/src/version/semantic_version_range.dart';

/// The conversions to versions and version ranges a parameter declared as
/// text can be given.
///
/// ```dart
/// final Parameter<SemanticVersion?> minimum =
///     parameter(['--min-version']).semanticVersion();
/// final Parameter<SemanticVersionRange?> accepts =
///     parameter(['--accepts']).semanticVersionRange();
/// ```
extension VersionParameterConverters on ParameterBuilder<String> {
  /// Converts the value to a [SemanticVersion], shown as `<version>` in the
  /// usage listing.
  ///
  /// The version is read strictly, exactly as [SemanticVersion.parse] reads
  /// it, and a value that is not one is reported with the reason - a
  /// leading zero, a malformed pre-release - rather than only as wrong.
  ///
  /// Returns a builder producing versions.
  ParameterBuilder<SemanticVersion> semanticVersion() =>
      convert<SemanticVersion>('version', _convertVersion);

  /// Converts the value to a [SemanticVersionRange], in either notation
  /// [SemanticVersionRange.parse] reads, shown as `<range>` in the usage
  /// listing.
  ///
  /// Returns a builder producing version ranges.
  ParameterBuilder<SemanticVersionRange> semanticVersionRange() =>
      convert<SemanticVersionRange>('range', _convertRange);
}

/// Reads [raw] as a semantic version.
///
/// Returns the version.
///
/// Throws a [ConversionException] saying why [raw] is not one.
SemanticVersion _convertVersion(String raw) {
  final VersionReading reading = readVersion(raw);
  return switch (reading) {
    VersionRead() => SemanticVersion.fromReading(reading),
    VersionRefused(:final reason) => throw ConversionException(
      'is not a semantic version: it $reason',
    ),
  };
}

/// Reads [raw] as a version range.
///
/// Returns the range.
///
/// Throws a [ConversionException] saying why [raw] is not one or matches
/// no version.
SemanticVersionRange _convertRange(String raw) {
  final RangeReading reading = readRange(raw);
  return switch (reading) {
    RangeRead() => SemanticVersionRange.fromReading(reading),
    RangeRefused(:final reason) => throw ConversionException(
      'is not a version range: it $reason',
    ),
  };
}
