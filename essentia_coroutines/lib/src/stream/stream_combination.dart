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

import 'package:essentia_coroutines/src/stream/combine_latest.dart';
import 'package:essentia_coroutines/src/stream/subscription_cancel.dart';

/// The combining operators for streams.
extension StreamCombination<T> on Stream<T> {
  /// Pairs every element of this stream with the element of [other] at the
  /// same position.
  ///
  /// The result ends as soon as either stream ends, and then cancels the
  /// other one. A stream that runs ahead is paused until the other one
  /// delivers its partner, so nothing is buffered beyond one element each.
  /// The first error of either stream is passed on, cancels both and ends
  /// the result. Pause, resume and cancel reach both streams.
  ///
  /// Returns a single subscription stream; every listener gets its own
  /// subscriptions of both streams.
  Stream<(T, R)> zip<R>(Stream<R> other) => Stream<(T, R)>.multi((sink) {
    final StreamSubscription<T> mine = listen(null);
    final StreamSubscription<R> theirs = other.listen(null);
    ({T value})? pendingMine;
    ({R value})? pendingTheirs;

    void pair() {
      final left = pendingMine;
      final right = pendingTheirs;
      if (left == null || right == null) {
        return;
      }
      pendingMine = null;
      pendingTheirs = null;
      mine.resume();
      theirs.resume();
      sink.add((left.value, right.value));
    }

    void end() {
      unawaited(mine.cancel());
      unawaited(theirs.cancel());
      unawaited(sink.close());
    }

    void fail(Object error, StackTrace stackTrace) {
      unawaited(mine.cancel());
      unawaited(theirs.cancel());
      sink.addError(error, stackTrace);
      unawaited(sink.close());
    }

    mine
      ..onData((value) {
        pendingMine = (value: value);
        mine.pause();
        pair();
      })
      ..onError(fail)
      ..onDone(end);
    theirs
      ..onData((value) {
        pendingTheirs = (value: value);
        theirs.pause();
        pair();
      })
      ..onError(fail)
      ..onDone(end);
    sink
      ..onPause = () {
        mine.pause();
        theirs.pause();
      }
      ..onResume = () {
        mine.resume();
        theirs.resume();
      }
      ..onCancel = () => <Future<void>>[
        keepInZone(mine.cancel()),
        keepInZone(theirs.cancel()),
      ].wait.then((_) {});
  });

  /// Combines the latest element of this stream with the latest element of
  /// [other] through [transform].
  ///
  /// Once both streams emitted, the result emits whenever either of them
  /// emits, with the latest element of each. The result ends once both
  /// ended. Errors of both streams and of [transform] are passed on without
  /// ending the result. Pause, resume and cancel reach both streams.
  ///
  /// ```dart
  /// final Stream<int> sum = a.counter.combine(b.counter, (a, b) => a + b);
  /// ```
  ///
  /// Returns a single subscription stream; every listener gets its own
  /// subscriptions of both streams.
  Stream<R> combine<S, R>(Stream<S> other, R Function(T a, S b) transform) =>
      combineLatest<Object?, R>(<Stream<Object?>>[
        this,
        other,
      ], (values) => transform(values[0] as T, values[1] as S));
}
