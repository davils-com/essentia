/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_core/essentia_core.dart';
import 'package:essentia_coroutines/src/continuation/suspension.dart';
import 'package:essentia_coroutines/src/deferred/deferred.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/job/job_support.dart';

/// Waiting for a collection of deferred values.
extension AwaitAll<T> on Iterable<Deferred<T>> {
  /// Waits for every deferred value.
  ///
  /// It fails as soon as one of them fails, without waiting for the others,
  /// and starts every lazily started one.
  ///
  /// Returns the values in the order of the deferred values.
  ///
  /// Throws the first failure, and a [CancellationException] if the waiting
  /// code is cancelled.
  Future<List<T>> awaitAll() {
    final List<Deferred<T>> all = toList();
    if (all.isEmpty) {
      return Future<List<T>>.value(<T>[]);
    }
    return suspendCancellableCoroutine<List<T>>((it) {
      final registrations = <Disposable>[];
      int remaining = all.length;
      void disposeAll() {
        for (final registration in registrations) {
          registration.dispose();
        }
      }

      for (final deferred in all) {
        deferred.start();
        registrations.add(
          deferred.invokeOnCompletion((cause) {
            if (!it.isActive) {
              return;
            }
            if (cause != null) {
              disposeAll();
              it.resumeWithException(cause, _stackTraceOf(deferred));
              return;
            }
            remaining--;
            if (remaining == 0) {
              it.resume(<T>[
                for (final completed in all) completed.getCompleted(),
              ]);
            }
          }),
        );
      }
      it.invokeOnCancellation((cause) => disposeAll());
    });
  }
}

/// Where [job] failed, if it is a job of this library that knows.
///
/// Returns the stack trace, or `null`.
StackTrace? _stackTraceOf(Object job) {
  if (job is JobSupport) {
    return job.completionError?.stackTrace;
  }
  return null;
}
