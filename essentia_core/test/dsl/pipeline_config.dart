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
