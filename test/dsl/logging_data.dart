/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';
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
