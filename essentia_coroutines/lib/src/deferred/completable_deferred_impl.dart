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

import 'package:essentia_coroutines/src/deferred/completable_deferred.dart';
import 'package:essentia_coroutines/src/deferred/deferred_mixin.dart';
import 'package:essentia_coroutines/src/job/job.dart';
import 'package:essentia_coroutines/src/job/job_support.dart';
import 'package:meta/meta.dart';

/// The deferred behind `CompletableDeferred()`.
@internal
final class CompletableDeferredImpl<T> extends JobSupport
    with DeferredMixin<T>
    implements CompletableDeferred<T> {
  /// Creates an active deferred, a child of [parent] if given.
  CompletableDeferredImpl([Job? parent]) : super(active: true) {
    initParentJob(parent);
  }

  /// The value it was completed with, `null` until then.
  ({T value})? _outcome;

  /// See [DeferredMixin.outcome].
  @override
  ({T value})? get outcome => _outcome;

  /// A deferred without a body is done with it once cancelled.
  @override
  bool get onCancelComplete => true;

  /// Names the kind of job.
  @override
  String get debugName => 'CompletableDeferred';

  /// See [CompletableDeferred.complete].
  @override
  bool complete(T value) {
    if (isCompleted || isBodyDone || isCancelled) {
      return false;
    }
    _outcome = (value: value);
    completeBody();
    return true;
  }

  /// See [CompletableDeferred.completeExceptionally].
  @override
  bool completeExceptionally(Object exception, [StackTrace? stackTrace]) {
    if (isCompleted || isBodyDone || isCancelled) {
      return false;
    }
    failBody(exception, stackTrace ?? StackTrace.current);
    return true;
  }
}
