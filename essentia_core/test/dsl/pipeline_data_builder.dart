/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';

import 'console_data_builder.dart';
import 'destination_data.dart';
import 'file_data_builder.dart';
import 'pipeline_data.dart';

/// Assembles a [PipelineData] out of console and file destinations.
final class PipelineDataBuilder extends ValidatingBuilder<PipelineData> {
  /// The destinations configured so far, whichever builder produced them.
  final _destinations = <DestinationData>[];

  /// Adds a console destination configured by [block].
  void console([void Function(ConsoleDataBuilder it)? block]) {
    collect<DestinationData, ConsoleDataBuilder>(
      _destinations,
      ConsoleDataBuilder(),
      'destinations',
      block ?? (_) {},
    );
  }

  /// Adds a file destination configured by [block].
  void file([void Function(FileDataBuilder it)? block]) {
    collect<DestinationData, FileDataBuilder>(
      _destinations,
      FileDataBuilder(),
      'destinations',
      block ?? (_) {},
    );
  }

  /// Assembles the pipeline.
  @override
  PipelineData assemble() =>
      PipelineData(List<DestinationData>.unmodifiable(_destinations));
}
