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
import 'package:essentia_coroutines/src/context/coroutine_context_zone.dart';
import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/job/job.dart';
import 'package:meta/meta.dart';

/// Runs [onCancelled] once the job of the current code is cancelled, the
/// hook that ends a stream listened to inside a coroutine together with
/// that coroutine.
///
/// A job that completes normally is not a cancellation: a stream listened
/// to by a coroutine whose body returned keeps running. A job that is
/// cancelled already runs [onCancelled] at once, in the caller's frame.
///
/// Returns the handle that stops watching, or `null` when the current code
/// runs outside every job.
@internal
Disposable? watchCancellation(
  void Function(CancellationException cause) onCancelled,
) {
  final Job? job = currentCoroutineContext().get(Job.key);
  if (job == null) {
    return null;
  }
  return job.invokeOnCompletion(onCancelling: true, (cause) {
    if (cause == null) {
      return;
    }
    onCancelled(
      cause is CancellationException ? cause : job.getCancellationException(),
    );
  });
}
