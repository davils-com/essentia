/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:meta/meta.dart';

/// What waits on a byte channel: nothing, the reader or the writer, or
/// nobody any more because the channel is closed.
@internal
sealed class ChannelSlot {
  /// Creates the slot.
  const ChannelSlot();
}

/// Nobody waits.
@internal
final class EmptySlot extends ChannelSlot {
  /// Creates the slot.
  const EmptySlot();
}

/// The channel is closed, with [cause] when it was cancelled.
@internal
final class ClosedSlot extends ChannelSlot {
  /// Creates the slot of a channel closed with [cause].
  const ClosedSlot(this.cause);

  /// What a waiter is resumed with: `null` for a channel closed normally.
  final Object? cause;
}

/// The reader or the writer waits, as [task] says, on [continuation].
@internal
final class TaskSlot extends ChannelSlot {
  /// Creates the slot of [task] waiting on [continuation].
  TaskSlot(this.task, this.continuation);

  /// What waits: `read` or `write`.
  final String task;

  /// What resumes the waiter.
  final CancellableContinuation<void> continuation;

  /// Resumes the waiter, with [cause] as its failure when there is one.
  void resume([Object? cause]) {
    if (!continuation.isActive) {
      return;
    }
    if (cause == null) {
      continuation.resume(null);
      return;
    }
    continuation.resumeWithException(cause);
  }
}
