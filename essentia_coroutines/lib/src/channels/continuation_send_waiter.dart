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
