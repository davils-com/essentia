/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

import 'package:essentia_coroutines/src/exception/cancellation_exception.dart';
import 'package:essentia_coroutines/src/job/job.dart';

/// The cancellation a job hands its children and its waiters.
///
/// It names the [job] that was cancelled, and the failure that cancelled
/// it as its [cause].
final class JobCancellationException extends CancellationException {
  /// Creates the exception for [job] with [message] and the failure that
  /// caused it.
  JobCancellationException(String message, {this.job, Object? cause})
    : super(message, cause);

  /// The job that was cancelled, if it is known.
  final Job? job;

  /// Renders the message, the job and the cause.
  @override
  String toString() {
    final buffer = StringBuffer('JobCancellationException: $message');
    final Job? cancelled = job;
    if (cancelled != null) {
      buffer.write('; job=$cancelled');
    }
    final Object? failure = cause;
    if (failure != null) {
      buffer.write('; cause=$failure');
    }
    return buffer.toString();
  }
}
