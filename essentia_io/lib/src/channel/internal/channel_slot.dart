/*
 * Copyright 2026 Davils
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
