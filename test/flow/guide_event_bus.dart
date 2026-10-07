/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/essentia.dart';

/// An event bus as Kotlin's documentation of `SharedFlow` shows it.
final class GuideEventBus {
  /// The private mutable flow.
  final _events = MutableSharedFlow<String>();

  /// The events, read-only.
  SharedFlow<String> get events => _events.asSharedFlow();

  /// Emits [event], waiting until every subscriber took it.
  ///
  /// Returns a future that completes then.
  Future<void> produceEvent(String event) => _events.emit(event);
}
