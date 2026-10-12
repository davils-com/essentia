/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:collection';

import 'package:meta/meta.dart';

/// A sender waiting until a channel takes its [element].
///
/// The channel resumes it before it moves the element anywhere, so a
/// waiter that cannot take part any more - a select that chose another
/// clause - keeps the element where it is.
@internal
abstract base class SendWaiter<E> extends LinkedListEntry<SendWaiter<E>> {
  /// Creates the waiter of a sender holding [element].
  SendWaiter(this.element);

  /// The element the sender waits to hand over.
  final E element;

  /// The select the waiter belongs to, `null` for a plain send.
  Object? get owner => null;

  /// Tells the sender that the channel took [element].
  ///
  /// Returns `false` when the sender is gone, so the element must stay.
  bool resume();

  /// Tells the sender that the channel was cancelled, with [error].
  ///
  /// Returns whether the sender was still there, so that its element counts
  /// as undelivered.
  bool fail(Object error);
}
