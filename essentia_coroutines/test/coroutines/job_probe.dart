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
