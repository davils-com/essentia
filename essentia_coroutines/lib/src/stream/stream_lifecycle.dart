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

import 'package:essentia_coroutines/src/stream/emission.dart';
import 'package:essentia_coroutines/src/stream/relay.dart';

/// The lifecycle operators for streams.
extension StreamLifecycle<T> on Stream<T> {
  /// Runs [action] whenever a listener starts listening, before this stream
  /// is listened to.
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

  /// Runs [action] once when this stream ends or the listener cancels.
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
  /// stream ends without an element.
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
