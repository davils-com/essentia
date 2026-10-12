/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_core/essentia_core.dart';

/// A [DisposableAsync] whose teardown waits until the test lets it drain.
final class DrainingResource implements DisposableAsync {
  /// Completed by the test once the teardown may finish.
  final drained = Completer<void>();

  /// How often the teardown actually started.
  var _disposals = 0;

  /// The teardown in progress or settled, or `null` before the first call.
  Future<void>? _teardown;

  /// How often the teardown actually started.
  int get disposals => _disposals;

  /// Starts the teardown, or joins the one already started.
  @override
  Future<void> dispose() => _teardown ??= _drain();

  /// Counts the teardown and waits until the test lets it drain.
  Future<void> _drain() async {
    _disposals++;
    await drained.future;
  }
}
