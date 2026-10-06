/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

import 'logging_data.dart';
import 'sink_builder.dart';
import 'sink_data.dart';

/// Assembles a [LoggingData].
final class LoggingBuilder extends ValidatingBuilder<LoggingData> {
  /// The root level.
  var level = 'INFO';

  /// The sinks configured so far.
  final _sinks = <SinkData>[];

  /// Adds a sink configured by [block].
  void sink(void Function(SinkBuilder it) block) {
    collect<SinkData, SinkBuilder>(_sinks, SinkBuilder(), 'sinks', block);
  }

  /// Assembles the configuration.
  @override
  LoggingData assemble() =>
      LoggingData(level, List<SinkData>.unmodifiable(_sinks));
}
