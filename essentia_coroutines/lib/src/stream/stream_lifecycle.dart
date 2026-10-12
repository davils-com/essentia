/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/src/stream/emission.dart';
import 'package:essentia_coroutines/src/stream/relay.dart';

/// Kotlin's lifecycle `Flow` operators for streams.
extension StreamLifecycle<T> on Stream<T> {
  /// Runs [action] whenever a listener starts listening, before this stream
  /// is listened to, the counterpart of Kotlin's `onStart`.
  ///
  /// An error thrown by [action] becomes an error event and ends the result
  /// without listening to this stream.
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  Stream<T> onStart(void Function() action) => Stream<T>.multi((controller) {
    if (!runCatchingInto(controller, action)) {
      unawaited(controller.close());
      return;
    }
    unawaited(controller.addStream(this).whenComplete(controller.close));
  }, isBroadcast: isBroadcast);

  /// Runs [action] once when this stream ends or the listener cancels, the
  /// counterpart of Kotlin's `onCompletion`.
  ///
  /// When this stream ends, an error thrown by [action] becomes an error
  /// event before the result ends. When the listener cancels, nobody
  /// listens any more, so such an error escapes to the current zone.
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  Stream<T> onCompletion(void Function() action) => relay<T, T>(this, (sink) {
    var completed = false;
    bool firstCompletion() => !completed && (completed = true);
    return (
      onData: sink.add,
      onDone: () {
        if (firstCompletion()) {
          runCatchingInto(sink, action);
        }
        unawaited(sink.close());
      },
      onCancel: () {
        if (firstCompletion()) {
          action();
        }
      },
    );
  });

  /// Emits the elements of the stream that [fallback] creates when this
  /// stream ends without an element, the counterpart of Kotlin's
  /// `onEmpty`.
  ///
  /// An error event does not count as an element.
  ///
  /// Returns a stream that is a broadcast stream exactly when this one is.
  Stream<T> onEmpty(Stream<T> Function() fallback) => relay<T, T>(this, (sink) {
    var empty = true;
    return (
      onData: (element) {
        empty = false;
        sink.add(element);
      },
      onDone: () => unawaited(
        (empty ? sink.addStream(fallback()) : Future<void>.value())
            .whenComplete(sink.close),
      ),
      onCancel: ignoringCancel,
    );
  });
}
