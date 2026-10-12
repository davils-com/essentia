/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:meta/meta.dart';

import 'destination_config.dart';

/// A pipeline, the root of the nested report format test.
@immutable
final class PipelineConfig implements Validatable {
  /// Creates the pipeline logging at [level] into [destinations].
  const PipelineConfig(this.level, this.destinations);

  /// The level that turns on a warning.
  static const traceLevel = 'TRACE';

  /// The root level.
  final String level;

  /// Where records go.
  final List<DestinationConfig> destinations;

  /// States what is wrong with the pipeline.
  @override
  void validate(ValidationScope scope) {
    if (destinations.isEmpty) {
      scope.fail(
        'at least one destination must be configured',
        property: 'destinations',
      );
    }
    if (level == traceLevel) {
      scope.warn(
        'trace on the root logger is expensive in production',
        property: 'level',
      );
    }
  }
}
