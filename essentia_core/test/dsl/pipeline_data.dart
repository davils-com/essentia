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

import 'destination_data.dart';

/// A pipeline whose destinations are built by different builders.
@immutable
final class PipelineData implements Validatable {
  /// Creates the pipeline sending records to [destinations].
  const PipelineData(this.destinations);

  /// Where records go.
  final List<DestinationData> destinations;

  /// States what is wrong with the pipeline.
  @override
  void validate(ValidationScope scope) {
    if (destinations.isEmpty) {
      scope.fail(
        'at least one destination must be configured',
        property: 'destinations',
      );
    }
  }
}
