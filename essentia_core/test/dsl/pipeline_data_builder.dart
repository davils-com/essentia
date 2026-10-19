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
