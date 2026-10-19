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
import 'package:essentia_coroutines/src/stream/subscription_cancel.dart';
import 'package:meta/meta.dart';

/// Combines the latest elements of [streams] with [transform].
///
/// Once every stream emitted at least once, the result emits what
/// [transform] makes of the latest element of each stream, in the order of
/// [streams], and again whenever any of them emits. [transform] gets an
/// unmodifiable snapshot of the latest elements. The result ends once
/// every stream ended; without streams it ends at once. Errors of the
/// streams and of [transform] are passed on without ending the result.
/// Pause, resume and cancel reach every stream.
///
/// ```dart
/// final Stream<int> total = combine(
///   <Stream<int>>[a.counter, b.counter],
///   (values) => values.sum,
/// );
/// ```
///
/// Returns a single subscription stream; every listener gets its own
/// subscriptions of the streams.
Stream<R> combine<T, R>(
  Iterable<Stream<T>> streams,
  R Function(List<T> values) transform,
) => combineLatest<T, R>(streams.toList(), transform);

/// Combines the latest elements of [streams] with [transform], the engine
/// behind `combine`.
///
/// Returns a single subscription stream.
@internal
Stream<R> combineLatest<T, R>(
  List<Stream<T>> streams,
  R Function(List<T> values) transform,
) => Stream<R>.multi((controller) {
  if (streams.isEmpty) {
    unawaited(controller.close());
    return;
  }
  final latest = List<({T value})?>.filled(streams.length, null);
  int missing = streams.length;
  int running = streams.length;
  final subscriptions = <StreamSubscription<T>>[];
  for (var position = 0; position < streams.length; position++) {
    subscriptions.add(
      streams[position].listen(
        (value) {
          if (latest[position] == null) {
            missing--;
          }
          latest[position] = (value: value);
          if (missing == 0) {
            final values = List<T>.unmodifiable(<T>[
              for (final ({T value})? element in latest) element!.value,
            ]);
            emitCatching(controller, () => transform(values));
          }
        },
        onError: controller.addError,
        onDone: () {
          running--;
          if (running == 0) {
            unawaited(controller.close());
          }
        },
      ),
    );
  }
  controller
    ..onPause = () {
      for (final subscription in subscriptions) {
        subscription.pause();
      }
    }
    ..onResume = () {
      for (final subscription in subscriptions) {
        subscription.resume();
      }
    }
    ..onCancel = () => <Future<void>>[
      for (final subscription in subscriptions)
        keepInZone(subscription.cancel()),
    ].wait.then((_) {});
});
