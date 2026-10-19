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

import 'sink_data.dart';

/// A logging configuration, the root of the validating builder tests.
@immutable
final class LoggingData implements Validatable {
  /// Creates the configuration logging at [level] into [sinks].
  const LoggingData(this.level, this.sinks);

  /// The level that turns on a warning.
  static const trace = 'TRACE';

  /// The root level.
  final String level;

  /// Where log records go.
  final List<SinkData> sinks;

  /// States what is wrong with the configuration.
  @override
  void validate(ValidationScope scope) {
    if (sinks.isEmpty) {
      scope.fail('at least one sink must be configured', property: 'sinks');
    }
    final Set<String> duplicates = _duplicateNames();
    if (duplicates.isNotEmpty) {
      scope.fail(
        'the sink names must be unique, found ${duplicates.join(', ')}',
        property: 'sinks',
      );
    }
    if (level == trace) {
      scope.warn(
        'trace on the root logger is expensive in production',
        property: 'level',
      );
    }
  }

  /// The names used by more than one sink.
  ///
  /// Returns them in the order they first appeared.
  Set<String> _duplicateNames() {
    final seen = <String>{};
    return <String>{
      for (final SinkData sink in sinks)
        if (!seen.add(sink.name)) sink.name,
    };
  }
}
