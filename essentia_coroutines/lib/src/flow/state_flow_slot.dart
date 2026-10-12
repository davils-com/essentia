/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// The place of one listener of a state flow, Kotlin's `StateFlowSlot`.
@internal
final class StateFlowSlot {
  /// Creates the slot of a new listener, which has the current value
  /// pending.
  StateFlowSlot();

  /// Whether the value may have changed since the listener looked last.
  var pending = true;

  /// Queues the pump of the listener, `null` until it is hooked up.
  void Function()? wake;
}
