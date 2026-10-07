/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia/src/coroutines/cancellation_exception.dart';
import 'package:essentia/src/coroutines/coroutine_context_zone.dart';
import 'package:essentia/src/coroutines/job.dart';
import 'package:essentia/src/lifecycle/disposable.dart';
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
