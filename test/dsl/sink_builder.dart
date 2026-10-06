/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

import 'async_builder.dart';
import 'async_data.dart';
import 'sink_data.dart';

/// Assembles a [SinkData].
final class SinkBuilder extends ValidatingBuilder<SinkData> {
  /// The name of the sink.
  var name = '';

  /// The asynchronous part configured so far.
  AsyncData? _queue;

  /// Makes the sink asynchronous, configured by [block].
  void async(void Function(AsyncBuilder it) block) {
    _queue = nested<AsyncData, AsyncBuilder>(AsyncBuilder(), 'async', block);
  }

  /// Assembles the sink.
  @override
  SinkData assemble() => SinkData(name, _queue);
}
