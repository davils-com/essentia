/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/time/clock.dart';
import 'package:essentia/src/time/time_source.dart';
import 'package:meta/meta.dart';

/// The zone value under which a virtual time travels.
@internal
const virtualTimeKey = #_virtualTime;

/// The time source and clock of a virtual time, as the system scheduler
/// sees them.
@internal
abstract interface class VirtualTime {
  /// The virtual time source.
  TimeSource get timeSource;

  /// The virtual clock.
  Clock get clock;
}

/// The virtual time the current code runs in.
///
/// Returns it, or `null` on real time.
@internal
VirtualTime? ambientVirtualTime() {
  final Object? value = Zone.current[virtualTimeKey];
  if (value is VirtualTime) {
    return value;
  }
  return null;
}
