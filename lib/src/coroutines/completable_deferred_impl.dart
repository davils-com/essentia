/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/coroutines/completable_deferred.dart';
import 'package:essentia/src/coroutines/deferred_mixin.dart';
import 'package:essentia/src/coroutines/job.dart';
import 'package:essentia/src/coroutines/job_support.dart';
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
