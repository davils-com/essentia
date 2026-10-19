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

import 'dart:async';

import 'package:essentia_coroutines/src/stream/relay_handlers.dart';
import 'package:essentia_coroutines/src/stream/subscription_cancel.dart';
import 'package:meta/meta.dart';

/// Relays [source] through the handlers that [handlersOf] creates for every
/// listener of the result.
///
/// Every listener gets its own subscription of [source] and its own
/// handlers, so per listener state such as a running index never leaks
/// between listeners. Pause, resume and cancel of the listener reach that
/// subscription, and errors of [source] are passed on with their stack
/// trace.
///
/// Returns a stream that is a broadcast stream exactly when [source] is.
@internal
Stream<R> relay<T, R>(
  Stream<T> source,
  RelayHandlers<T> Function(StreamController<R> sink) handlersOf,
) => Stream<R>.multi((controller) {
  final RelayHandlers<T> handlers = handlersOf(controller);
  final StreamSubscription<T> subscription = source.listen(
    handlers.onData,
    onError: controller.addError,
    onDone: handlers.onDone,
  );
  controller
    ..onPause = subscription.pause
    ..onResume = subscription.resume
    ..onCancel = () {
      handlers.onCancel();
      return keepInZone(subscription.cancel());
    };
}, isBroadcast: source.isBroadcast);

/// An `onDone` handler that closes [sink].
///
/// Returns the handler.
@internal
void Function() closing(StreamController<Object?> sink) =>
    () => unawaited(sink.close());

/// An `onCancel` handler for a relay that has nothing to do on cancel.
@internal
void ignoringCancel() {}
