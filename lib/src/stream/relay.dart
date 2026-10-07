/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia/src/stream/relay_handlers.dart';
import 'package:essentia/src/stream/subscription_cancel.dart';
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
