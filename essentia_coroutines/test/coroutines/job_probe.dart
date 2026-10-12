/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'dart:async';

import 'package:essentia_coroutines/essentia_coroutines.dart';

import 'job_table_event.dart';

/// A coroutine under test and the levers that move it on.
final class JobProbe {
  /// Creates the probe of [job], whose body waits for [gate] and then, in a
  /// `finally`, for [release], failing events with [failure].
  JobProbe(this.job, this.gate, this.release, this.failure);

  /// The coroutine.
  final Job job;

  /// What the body waits for, cancellably.
  final CompletableDeferred<bool> gate;

  /// What the body waits for in its `finally`, not cancellably.
  final Completer<void> release;

  /// The failure the failing events fail with.
  final Object failure;

  /// The child that keeps a completing coroutine from completing.
  CompletableJob? holder;

  /// Applies [event].
  void apply(JobTableEvent event) {
    switch (event) {
      case JobTableEvent.start:
        job.start();
      case JobTableEvent.cancel:
        job.cancel();
      case JobTableEvent.complete:
        gate.complete(true);
        if (!release.isCompleted) {
          release.complete();
        }
      case JobTableEvent.completeExceptionally:
        gate.completeExceptionally(failure);
        if (!release.isCompleted) {
          release.completeError(failure);
        }
      case JobTableEvent.childComplete:
        (holder ?? CompletableJob(job)).complete();
      case JobTableEvent.childFail:
        (holder ?? CompletableJob(job)).completeExceptionally(failure);
    }
  }
}
