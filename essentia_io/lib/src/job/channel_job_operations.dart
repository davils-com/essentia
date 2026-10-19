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
import 'package:essentia_coroutines/essentia_coroutines.dart';
import 'package:essentia_io/src/job/channel_job.dart';

/// The operations on a [ChannelJob], all on its [ChannelJob.job].
extension ChannelJobOperations on ChannelJob {
  /// Whether the coroutine completed.
  bool get isCompleted => job.isCompleted;

  /// Whether the coroutine was cancelled.
  bool get isCancelled => job.isCancelled;

  /// Waits until the coroutine completed.
  Future<void> join() => job.join();

  /// Cancels the coroutine.
  void cancel() {
    job.cancel();
  }

  /// Why the coroutine was cancelled.
  ///
  /// Returns the cancellation.
  CancellationException getCancellationException() =>
      job.getCancellationException();

  /// Runs [handler] once the coroutine completed, with the failure it
  /// completed with.
  ///
  /// Returns a handle whose `dispose` removes the handler again.
  Disposable invokeOnCompletion(void Function(Object? cause) handler) =>
      job.invokeOnCompletion(handler);
}
