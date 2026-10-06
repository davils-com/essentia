/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

import 'destination_config.dart';
import 'destination_config_builder.dart';
import 'pipeline_config.dart';

/// Assembles a [PipelineConfig].
final class PipelineConfigBuilder extends ValidatingBuilder<PipelineConfig> {
  /// The root level.
  var level = 'INFO';

  /// The destinations configured so far.
  final _destinations = <DestinationConfig>[];

  /// Adds a destination configured by [block].
  void destination(void Function(DestinationConfigBuilder it) block) {
    collect<DestinationConfig, DestinationConfigBuilder>(
      _destinations,
      DestinationConfigBuilder(),
      'destinations',
      block,
    );
  }

  /// Assembles the pipeline.
  @override
  PipelineConfig assemble() => PipelineConfig(
    level,
    List<DestinationConfig>.unmodifiable(_destinations),
  );
}
