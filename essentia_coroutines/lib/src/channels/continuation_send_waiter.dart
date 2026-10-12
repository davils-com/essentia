/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/channels/send_waiter.dart';
import 'package:essentia_coroutines/src/continuation/cancellable_continuation.dart';
import 'package:meta/meta.dart';

/// The waiter of a plain `send`, resumed through its continuation.
@internal
final class ContinuationSendWaiter<E> extends SendWaiter<E> {
  /// Creates the waiter of a send of [element] that waits in
  /// [_continuation].
  ContinuationSendWaiter(super.element, this._continuation);

  /// The continuation of the waiting send.
  final CancellableContinuation<void> _continuation;

  /// See [SendWaiter.resume].
  @override
  bool resume() {
    if (!_continuation.isActive) {
      return false;
    }
    _continuation.resume(null);
    return true;
  }

  /// See [SendWaiter.fail].
  @override
  bool fail(Object error) {
    if (!_continuation.isActive) {
      return false;
    }
    _continuation.resumeWithException(error, StackTrace.current);
    return true;
  }
}
