/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:collection';

import 'package:essentia_coroutines/src/channels/channel_closed.dart';
import 'package:essentia_coroutines/src/channels/channel_result.dart';
import 'package:meta/meta.dart';

/// A receiver waiting until a channel hands it an element or is closed.
@internal
abstract base class ReceiveWaiter<E> extends LinkedListEntry<ReceiveWaiter<E>> {
  /// The select the waiter belongs to, `null` for a plain receive.
  Object? get owner => null;

  /// Hands [result] to the receiver: a [ChannelSuccess] with an element, or
  /// a [ChannelClosed] once nothing more will come.
  ///
  /// Returns `false` when the receiver is gone, so an element must stay in
  /// the channel.
  bool resume(ChannelResult<E> result);
}
