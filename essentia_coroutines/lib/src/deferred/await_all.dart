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
