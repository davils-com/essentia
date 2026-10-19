/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:meta/meta.dart';

/// The place of one listener in the buffer of a shared flow.
@internal
final class SharedFlowSlot {
  /// Creates the slot of a listener that takes the value at [index] next.
  SharedFlowSlot(this.index);

  /// The index of the value the listener takes next, `-1` once it left.
  int index;

  /// Whether the listener waits for a value.
  var waiting = false;

  /// Queues the pump of the listener, `null` until it is hooked up.
  void Function()? wake;
}
