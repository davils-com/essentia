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

/// The operations on a `Job` built from its contract.
extension JobOperations on Job {
  /// Cancels the job and waits until it is complete.
  ///
  /// Returns a future that completes once the job is complete.
  Future<void> cancelAndJoin([CancellationException? cause]) {
    cancel(cause);
    return join();
  }

  /// Cancels every child of the job, not the job itself.
  void cancelChildren([CancellationException? cause]) {
    for (final Job child in children.toList()) {
      child.cancel(cause);
    }
  }

  /// Throws if the job is not active.
  ///
  /// Throws the [CancellationException] of the job if it is cancelling,
  /// cancelled or complete.
  void ensureActive() {
    if (!isActive) {
      throw getCancellationException();
    }
  }
}
