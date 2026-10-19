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
