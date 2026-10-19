/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
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
