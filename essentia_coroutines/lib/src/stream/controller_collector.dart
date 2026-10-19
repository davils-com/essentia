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

import 'package:essentia_coroutines/src/context/coroutine_context.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_access.dart';
import 'package:essentia_coroutines/src/context/coroutine_context_zone.dart';
import 'package:essentia_coroutines/src/continuation/cancellable_continuation.dart';
import 'package:essentia_coroutines/src/continuation/suspension.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/flow/flow_collector.dart';
import 'package:meta/meta.dart';

/// A [FlowCollector] that emits into a stream controller and waits while
/// the listener of the controller is paused.
///
/// The owner of the controller calls [release] when the listener resumes
/// or cancels.
@internal
final class ControllerCollector<T> implements FlowCollector<T> {
  /// Creates the collector emitting into [_controller].
  ControllerCollector(this._controller);

  /// The controller the values go to.
  final StreamController<T> _controller;

  /// The emitters waiting for the listener to resume.
  final _waiting = <CancellableContinuation<void>>[];

  /// Emits [value] to the listener.
  ///
  /// Returns a future that completes at once, or once the listener resumes
  /// when it is paused.
  ///
  /// Throws a [CancellationException] if the emitting code is cancelled or
  /// the listener cancelled.
  @override
  Future<void> emit(T value) {
    final CoroutineContext context = currentCoroutineContext();
    if (!context.isActive) {
      return Future<void>.error(context.job.getCancellationException());
    }
    if (!_controller.hasListener) {
      return Future<void>.error(
        const CancellationException('The listener cancelled'),
      );
    }
    _controller.add(value);
    if (!_controller.isPaused) {
      return Future<void>.value();
    }
    return suspendCancellableCoroutine<void>((it) {
      _waiting.add(it);
      it.invokeOnCancellation((cause) => _waiting.remove(it));
    });
  }

  /// Lets the emitters waiting for the listener go on.
  void release() {
    final waiting = List<CancellableContinuation<void>>.of(_waiting);
    _waiting.clear();
    for (final emitter in waiting) {
      emitter.resume(null);
    }
  }
}
